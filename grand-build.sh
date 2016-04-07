#!/bin/bash
#
# Copyright 2016 Free Software Foundation, Inc.
#
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Radio; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.


# Known dependencies:
#  - cmake, git, make, xutils-dev, automake, autoconf, libtool, wget, perl, tar, sed
# Need to have installed Android Studio, Android SDK, and Android NDK
#
# Tested only on Ubuntu 15.10, 64-bit



if [ -z "$PREFIX" ];
then
    echo "PREFIX not set; defaulting to /opt/grandroid"
    PREFIX=/opt/grandroid
fi

if [ -z "$ANDROID_SDK" ];
then
    echo "Please set ANDROID_SDK to point to the location of the Android SDK (e.g., /opt/android)"
    exit
fi

if [ -z "$ANDROID_NDK" ];
then
    echo "Please set ANDROID_NDK to point to the location of the Android NDK (e.g., /opt/ndk)"
    exit
fi

if [ -z "$PARALLEL" ];
then
    echo "Parellelism is unset; setting to 1"
    PARALLEL=1
fi

set -e

echo "Asking for sudo permissions to create prefix directory ${PREFIX}"
sudo mkdir -p ${PREFIX}
sudo chown $USER:$USER -R ${PREFIX}
sudo -K # invalidates credentials for anyone paranoid

ANDROID_MIN_API_VERSION=21
ANDROID_STANDALONE_TOOLCHAIN=${PREFIX}/android-toolchain
PATH_ORIG=$PATH
PATH=$PATH:$ANDROID_STANDALONE_TOOLCHAIN/bin:$ANDROID_SDK/tools:$ANDROID_NDK
TOP_BUILD_DIR=`pwd`

${ANDROID_NDK}/build/tools/make-standalone-toolchain.sh --stl=gnustl --arch=arm --platform=android-${ANDROID_MIN_API_VERSION} --abis=armeabi-v7a --install-dir=${ANDROID_STANDALONE_TOOLCHAIN}


###########################################################
#                   BOOST DEPENDENCY
###########################################################

echo ""; echo ""; echo ""; echo ""

BOOST_VER=1.58.0
BOOST_DIR=boost_1_58_0
BOOST_URL="http://jaist.dl.sourceforge.net/project/boost/boost/1.58.0/boost_1_58_0.tar.bz2"

if [ -e "${BOOST_DIR}.tar.bz2" ];
then
    echo "Boost file already downloaded; skipping"
else
    echo "Downloading Boost tarball"
    wget ${BOOST_URL}
fi

if [ -d ${BOOST_DIR} ];
then
    echo "Boost directory expanded; skipping"
else
    echo "Expanding Boost tarball"
    tar xjf ${BOOST_DIR}.tar.bz2
    chmod +r -R ${BOOST_DIR}
fi

cd ${BOOST_DIR}
echo "import os ;

local ANDROID_STANDALONE_TOOLCHAIN = [ os.environ ANDROID_STANDALONE_TOOLCHAIN ] ;

using gcc : android :
     ${ANDROID_STANDALONE_TOOLCHAIN}/bin/arm-linux-androideabi-g++ :
     <compileflags>--sysroot=${ANDROID_STANDALONE_TOOLCHAIN}/sysroot
     <compileflags>-march=armv7-a
     <compileflags>-mfloat-abi=softfp
     <compileflags>-Os
     <compileflags>-fno-strict-aliasing
     <compileflags>-O2
     <compileflags>-DNDEBUG
     <compileflags>-g
     <compileflags>-lstdc++
     <compileflags>-I${ANDROID_STANDALONE_TOOLCHAIN}/include/c++/4.8/
     <compileflags>-I${ANDROID_STANDALONE_TOOLCHAIN}/include/c++/4.8/arm-linux-androideabi/armv7-a
     <compileflags>-D__GLIBC__
     <compileflags>-D_GLIBCXX__PTHREADS
     <compileflags>-D__arm__
     <compileflags>-D_REENTRANT
     <compileflags>-DBOOST_SP_USE_PTHREADS
     <compileflags>-L${ANDROID_STANDALONE_TOOLCHAIN}/lib/gcc/arm-linux-androideabi/4.8/
     <archiver>${ANDROID_STANDALONE_TOOLCHAIN}/bin/arm-linux-androideabi-ar
     <ranlib>${ANDROID_STANDALONE_TOOLCHAIN}/bin/arm-linux-androideabi-ranlib
     ;" > tools/build/src/user-config.jam

echo "Boostrapping and Building"
./bootstrap.sh
./b2 \
  --without-python --without-container --without-context \
  --without-coroutine --without-graph --without-graph_parallel \
  --without-iostreams --without-locale --without-log --without-math \
  --without-mpi --without-signals --without-timer --without-wave \
  link=static runtime-link=static threading=multi threadapi=pthread \
  target-os=linux --stagedir=android --build-dir=android \
  stage

echo "Installing"
./b2 \
  --without-python --without-container --without-context \
  --without-coroutine --without-graph --without-graph_parallel \
  --without-iostreams --without-locale --without-log --without-math \
  --without-mpi --without-signals --without-timer --without-wave \
  link=static runtime-link=static threading=multi threadapi=pthread \
  target-os=linux --stagedir=android --build-dir=android \
  --prefix=$PREFIX install

cd ${TOP_BUILD_DIR}


############################################################
##                   FFTW DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#FFTW_VER=3.3.4
#FFTW_DIR=fftw-${FFTW_VER}
#FFTW_URL="http://www.fftw.org/${FFTW_DIR}.tar.gz"
#
#if [ -e "${FFTW_DIR}.tar.gz" ];
#then
#    echo "FFTW file already downloaded; skipping"
#else
#    echo "Downloading FFTW tarball"
#    wget ${FFTW_URL}
#fi
#
#if [ -d ${FFTW_DIR} ];
#then
#    echo "FFTW directory expanded; skipping"
#else
#    echo "Expanding FFTW tarball"
#    tar xzf ${FFTW_DIR}.tar.gz
#    chmod +r -R ${FFTW_DIR}
#fi
#
#cd ${FFTW_DIR}
#
#mkdir -p build
#cd build
#
#export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot"
#export CC="arm-linux-androideabi-gcc --sysroot=$SYS_ROOT"
#export LD="arm-linux-androideabi-ld"
#export AR="arm-linux-androideabi-ar"
#export RANLIB="arm-linux-androideabi-ranlib"
#export STRIP="arm-linux-androideabi-strip"
#
#echo ""; echo ""
#echo "Configuring FFTW"
#../configure --enable-single --enable-static --enable-threads \
#  --enable-float  --enable-neon \
#  --host=armv7-eabi --build=x86_64-linux \
#  --prefix=$PREFIX \
#  LIBS="-lc -lgcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon" \
#  CC="arm-linux-androideabi-gcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon"
#
#echo "\n\nBuilding and installing FFTW"
#make -s -j${PARALLEL}
#make -s install
#
#unset SYS_ROOT
#unset CC
#unset LD
#unset AR
#unset RANLIB
#unset STRIP
#
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##            OpenSSL (libcrypto) DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
## Crete a new environment that will screw with the normal one
#PATH_OLD=$PATH
#
#PATH=$ANDROID_NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86_64/bin:$PATH_ORIG
#ANDROID_NDK_ROOT=$ANDROID_NDK
#
#echo $PATH
#
#OPENSSL_VER=1.0.2
#OPENSSL_VER_PATCH=a
#OPENSSL_DIR=openssl-${OPENSSL_VER}${OPENSSL_VER_PATCH}
#OPENSSL_URL="ftp://ftp.openssl.org/source/old/${OPENSSL_VER}/${OPENSSL_DIR}.tar.gz"
#
#if [ -e "${OPENSSL_DIR}.tar.gz" ];
#then
#    echo "OpenSSL file already downloaded; skipping"
#else
#    echo "Downloading OpenSSL tarball"
#    wget ${OPENSSL_URL}
#fi
#
#if [ -d ${OPENSSL_DIR} ];
#then
#    echo "OpenSSL directory expanded; skipping"
#else
#    echo "Expanding OpenSSL tarball"
#    tar xzf ${OPENSSL_DIR}.tar.gz
#    chmod +r -R ${OPENSSL_DIR}
#fi
#
#cd ${OPENSSL_DIR}
#
#wget https://wiki.openssl.org/images/7/70/Setenv-android.sh
#chmod +x Setenv-android.sh
#. ./Setenv-android.sh
#perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org
#./config --prefix=/usr shared no-ssl2 no-ssl3 no-comp no-hw no-engines --openssldir=$ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/ssl/$ANDROID_API
#
#echo ""; #echo ""
#echo "Making and installing OpenSSL"
#make depend
#make all
#
#echo ""; echo ""
#echo "Copying and linking OpenSSL files"
#cp -fv libcrypto.* $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/lib
#cp -fv libssl.* $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/lib/
#mkdir -p $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/include
#cp -rLfv include/openssl $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/include
#
## reset our path
#PATH=$PATH_OLD
#
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##          APACHE THRIFT DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#THRIFT_VER=0.9.3
#THRIFT_DIR=thrift
#
#if [ -d ${THRIFT_DIR} ];
#then
#    echo "Thrift directory exists; skipping"
#else
#    echo "Git cloning Thrift"
#    git clone https://git-wip-us.apache.org/repos/asf/thrift.git thrift
#fi
#
#cd thrift
#git checkout ${THRIFT_VER}
#
#sed -e '/AC_FUNC_MALLOC/ s/^#*/#/' -i configure.ac
#sed -e '/AC_FUNC_REALLOC/ s/^#*/#/' -i configure.ac
#
#echo ""; echo ""
#echo "Configuring Thrift"
#export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot/"
#export CC="arm-linux-androideabi-g++ --sysroot=$SYS_ROOT"
#export CXX="arm-linux-androideabi-g++ --sysroot=$SYS_ROOT"
#export LD="arm-linux-androideabi-ld"
#export AR="arm-linux-androideabi-ar"
#export RANLIB="arm-linux-androideabi-ranlib"
#export STRIP="arm-linux-androideabi-strip"
#./bootstrap.sh
#./configure --prefix=$PREFIX   --disable-tests --disable-tutorial --with-cpp \
# --without-python --without-c_glib --without-php --without-csharp --without-java \
# --without-libevent --without-zlib \
# --with-boost=$PREFIX --host=arm-eabi --build=x86_64-linux \
# CPPFLAGS="-I$ANDROID_STANDALONE_TOOLCHAIN/include/c++/4.8/arm-linux-androideabi/armv7-a" \
# LDFLAGS="-L$ANDROID_STANDALONE_TOOLCHAIN/arm-linux-androideabi/lib/armv7-a -lgnustl_shared"
#
#echo ""; echo ""
#echo "Building and installing Thrift"
#make -s -j${PARALLEL}
#make -s install
#
#unset SYS_ROOT
#unset CC
#unset CXX
#unset LD
#unset AR
#unset RANLIB
#unset STRIP
#
#cd ${TOP_BUILD_DIR}
#
#
#
#
############################################################
##          ZEROMQ DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#ZEROMQ_VER=3.2.4
#ZEROMQ_DIR=zeromq-${ZEROMQ_VER}
#ZEROMQ_URL="http://download.zeromq.org/${ZEROMQ_DIR}.tar.gz"
#
#if [ -e "${ZEROMQ_DIR}.tar.gz" ];
#then
#    echo "ZEROMQ file already downloaded; skipping"
#else
#    echo "Downloading ZEROMQ tarball"
#    wget ${ZEROMQ_URL}
#fi
#
#if [ -d ${ZEROMQ_DIR} ];
#then
#    echo "ZEROMQ directory expanded; skipping"
#else
#    echo "Expanding ZEROMQ tarball"
#    tar xzf ${ZEROMQ_DIR}.tar.gz
#    chmod +r -R ${ZEROMQ_DIR}
#fi
#
#cd ${ZEROMQ_DIR}
#
#sed -e 's/libzmq_werror="yes"/libzmq_werror="no"/' -i configure
#
#echo ""; echo ""
#echo "Configuring ZMQ"
#./configure --enable-static --disable-shared --host=arm-linux-androideabi \
#    --prefix=$PREFIX LDFLAGS="-L$OUTPUT_DIR/lib \
#    -L$ANDROID_STANDALONE_TOOLCHAIN/arm-linux-androideabi/lib/armv7-a \
#    -lgnustl_shared" CPPFLAGS="-fPIC -I$PREFIX/include \
#    -I$ANDROID_STANDALONE_TOOLCHAIN/include/c++/4.8/arm-linux-androideabi/armv7-a" \
#    LIBS="-lgcc" --with-libsodium=no
#
#echo ""; echo ""
#echo "Building and installing ZMQ"
#make -s -j${PARALLEL}
#make -s install
#
#echo ""; echo ""
#echo "Getting C++ Header for ZMQ"
#wget -O $PREFIX/include/zmq.hpp https://raw.githubusercontent.com/zeromq/cppzmq/master/zmq.hpp
#
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##          DOWNLOAD GNURADIO
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#GNURADIO_DIR=gnuradio
#
#if [ -e "${GNURADIO_DIR}" ];
#then
#    echo "GNURADIO file already cloned; skipping"
#else
#    echo "Git cloning GNURADIO"
#    git clone git://git.gnuradio.org/gnuradio.git
#fi
#
#cd gnuradio
#git checkout android
#TOOLCHAIN=`pwd`/cmake/Toolchains/AndroidToolchain.cmake
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##          LIBUSB DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#LIBUSB_DIR=libusb
#LIBUSB_VER=v1.0.19-and5
#
#if [ -e "${LIBUSB_DIR}" ];
#then
#    echo "LIBUSB file already cloned; skipping"
#else
#    echo "Git cloning LIBUSB"
#    git clone https://github.com/trondeau/${LIBUSB_DIR}
#fi
#
#cd ${LIBUSB_DIR}
#git checkout ${LIBUSB_VER}
#
#echo "Building libUSB via ndk-build"
#cd android/jni
#ndk-build
#
#echo "Copying libUSB files to $PREFIX"
#cp -Lfv ${TOP_BUILD_DIR}/${LIBUSB_DIR}/android/libs/armeabi-v7a/libusb1.0.so $PREFIX/lib
#cp -rLfv ${TOP_BUILD_DIR}/${LIBUSB_DIR}/libusb $PREFIX/include
#
#cd ${TOP_BUILD_DIR}
#
#
############################################################
##          RTLSDR DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#RTLSDR_DIR=rtl-sdr
#RTLSDR_VER=android5
#
#if [ -e "${RTLSDR_DIR}" ];
#then
#    echo "RTLSDR file already cloned; skipping"
#else
#    echo "Git cloning RTLSDR"
#    git clone https://github.com/trondeau/${RTLSDR_DIR}
#fi
#
#cd ${RTLSDR_DIR}
#git checkout ${RTLSDR_VER}
#
#echo ""; echo ""
#echo "Configuring RTL-SDR"
#mkdir -p build
#cd build
#
#set +e # expecting this call to cmake to fail
#cmake -Wno-dev \
#      -DCMAKE_INSTALL_PREFIX=$PREFIX \
#      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
#      -DLIBUSB_INCLUDE_DIR=$PREFIX/include/libusb \
#      -DLIBUSB_LIBRARIES=$PREFIX/lib/libusb1.0.so \
#      ../
#
#set -e
#cmake -Wno-dev \
#      -DCMAKE_INSTALL_PREFIX=$PREFIX \
#      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
#      -DLIBUSB_INCLUDE_DIR=$PREFIX/include/libusb \
#      -DLIBUSB_LIBRARIES=$PREFIX/lib/libusb1.0.so \
#      ../
#
#echo ""; echo ""
#echo "Building and installing RTL-SDR"
#make -s -j${PARALLEL}
#make -s install
#
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##          UHD DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#UHD_DIR=uhd
#UHD_VER=android
#
#if [ -e "${UHD_DIR}" ];
#then
#    echo "UHD file already cloned; skipping"
#else
#    echo "Git cloning UHD"
#    git clone https://github.com/trondeau/${UHD_DIR}
#fi
#
#cd ${UHD_DIR}/host
#git checkout ${UHD_VER}
#
#echo ""; echo ""
#echo "Configuring UHD"
#mkdir -p build
#cd build
#cmake -Wno-dev \
#      -DCMAKE_INSTALL_PREFIX=$PREFIX \
#      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
#      -DBOOST_ROOT=$PREFIX \
#      -DBoost_DIR=$PREFIX \
#      -DLIBUSB_INCLUDE_DIRS=$PREFIX/include/libusb \
#      -DLIBUSB_LIBRARIES=$PREFIX/lib/libusb1.0.so \
#      -DPYTHON_EXECUTABLE=/usr/bin/python \
#      -DENABLE_STATIC_LIBS=True -DENABLE_USRP1=False \
#      -DENABLE_USRP2=False -DENABLE_B100=False \
#      -DENABLE_X300=False -DENABLE_OCTOCLOCK=False \
#      -DENABLE_TESTS=False -DENABLE_ORC=False \
#      ../
#
#echo ""; echo ""
#echo "Building and installing UHD"
#make -s -j${PARALLEL}
#make -s install
#
#cd ${TOP_BUILD_DIR}
#
#
#
#
############################################################
##          VOLK DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#VOLK_DIR=volk
#VOLK_VER=android
#
#if [ -e "${VOLK_DIR}" ];
#then
#    echo "VOLK file already cloned; skipping"
#else
#    echo "Git cloning VOLK"
#    git clone https://github.com/trondeau/${VOLK_DIR}
#fi
#
#cd ${VOLK_DIR}
#git checkout ${VOLK_VER}
#
#echo ""; echo ""
#echo "Configuring VOLK"
#mkdir -p build
#cd build
#cmake -Wno-dev \
#      -DCMAKE_INSTALL_PREFIX=$PREFIX \
#      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
#      -DPYTHON_EXECUTABLE=/usr/bin/python \
#      -DENABLE_STATIC_LIBS=True \
#      ../
#
#echo ""; echo ""
#echo "Building and installing VOLK"
#make -s -j${PARALLEL}
#make -s install
#
#cd ${TOP_BUILD_DIR}
#
#
#
#
############################################################
##          BUILDING GNURADIO
############################################################
#
#cd ${GNURADIO_DIR}
#
#echo ""; echo ""
#echo ${PATH}
#echo "Configuring GNU Radio"
#mkdir -p build
#cd build
#cmake \
#    -Wno-dev \
#    -DCMAKE_INSTALL_PREFIX=$PREFIX \
#    -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
#    -DENABLE_INTERNAL_VOLK=Off \
#    -DBOOST_ROOT=$PREFIX \
#    -DFFTW3F_INCLUDE_DIRS=$PREFIX/include \
#    -DFFTW3F_LIBRARIES=$PREFIX/lib/libfftw3f.a \
#    -DFFTW3F_THREADS_LIBRARIES=$PREFIX/lib/libfftw3f_threads.a \
#    -DENABLE_DEFAULT=False \
#    -DENABLE_GR_LOG=False \
#    -DENABLE_VOLK=True \
#    -DENABLE_GNURADIO_RUNTIME=True \
#    -DENABLE_GR_BLOCKS=True \
#    -DENABLE_GR_FEC=False \
#    -DENABLE_GR_FFT=True \
#    -DENABLE_GR_FILTER=True \
#    -DENABLE_GR_ANALOG=True \
#    -DENABLE_GR_DIGITAL=True \
#    -DENABLE_GR_CHANNELS=True \
#    -DENABLE_GR_ZEROMQ=True \
#    -DENABLE_GR_UHD=True \
#    -DENABLE_STATIC_LIBS=True \
#    -DENABLE_GR_CTRLPORT=True \
#    ../
#
#echo ""; echo ""
#echo "Building and installing GNU Radio"
#make -j${PARALLEL}
#make install
#
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##          GRAnd
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#GRAND_DIR=gr-grand
#GRAND_VER=master
#
#if [ -e "${GRAND_DIR}" ];
#then
#    echo "gr-grand file already cloned; skipping"
#else
#    echo "Git cloning gr-grand"
#    git clone https://github.com/trondeau/${GRAND_DIR}
#fi
#
#cd ${GRAND_DIR}
#git checkout ${GRAND_VER}
#
#echo ""; echo ""
#echo "Configuring GRAND"
#mkdir -p build
#cd build
#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
#cmake -Wno-dev \
#      -DCMAKE_INSTALL_PREFIX=$PREFIX \
#      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
#      -DPYTHON_EXECUTABLE=/usr/bin/python \
#      ../
#
#echo ""; echo ""
#echo "Building and installing gr-grand"
#make -s -j${PARALLEL}
#make -s install
#
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##          GR-OSMOSDR DEPENDENCY
############################################################
#
#echo ""; echo ""; echo ""; echo ""
#
#OSMOSDR_DIR=gr-osmosdr
#OSMOSDR_VER=android5
#
#if [ -e "${OSMOSDR_DIR}" ];
#then
#    echo "gr-osmosdr file already cloned; skipping"
#else
#    echo "Git cloning gr-osmosdr"
#    git clone https://github.com/trondeau/${OSMOSDR_DIR}
#fi
#
#cd ${OSMOSDR_DIR}
#git checkout ${OSMOSDR_VER}
#
#echo ""; echo ""
#echo "Configuring OSMOSDR"
#mkdir -p build
#cd build
#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
#cmake -Wno-dev \
#      -DCMAKE_INSTALL_PREFIX=$PREFIX \
#      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
#      -DENABLE_UHD=True -DENABLE_FCD=False -DENABLE_RFSPACE=False \
#      -DENABLE_BLADERF=False -DENABLE_HACKRF=False -DENABLE_OSMOSDR=False \
#      -DENABLE_RTL_TCP=False -DENABLE_IQBALANCE=False \
#      -DBOOST_ROOT=$PREFIX \
#      ../
#
#echo ""; echo ""
#echo "Building and installing OSMOSDR"
#make -s -j${PARALLEL}
#make -s install
#
#cd ${TOP_BUILD_DIR}
#
#
#
############################################################
##          BUILD MANIFEST FILE
############################################################
#
#cd ${TOP_BUILD_DIR}
#cd ${RTLSDR_DIR}
#RTLSDR_VER=`git rev-parse HEAD`
#
#cd ${TOP_BUILD_DIR}
#cd ${UHD_DIR}
#UHD_VER=`git rev-parse HEAD`
#
#cd ${TOP_BUILD_DIR}
#cd ${VOLK_DIR}
#VOLK_VER=`git rev-parse HEAD`
#
#cd ${TOP_BUILD_DIR}
#cd ${GNURADIO_DIR}
#GNURADIO_VER=`git rev-parse HEAD`
#
#cd ${TOP_BUILD_DIR}
#cd ${OSMOSDR_DIR}
#OSMOSDR_VER=`git rev-parse HEAD`
#
#echo "Boost: ${BOOST_VER}" > ${PREFIX}/MANIFEST.txt
#echo "FFTW: ${FFTW_VER}"   >> ${PREFIX}/MANIFEST.txt
#echo "OpenSSL: ${OPENSSL_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "Thrift: ${THRIFT_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "ZeroMQ: ${ZEROMQ_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "LibUSB: ${LIBUSB_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "RTL-SDR: ${RTLSDR_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "UHD: ${UHD_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "VOLK: ${VOLK_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "gr-omsosdr: ${OSMOSDR_VER}" >> ${PREFIX}/MANIFEST.txt
#echo "GNU Radio: ${GNURADIO_VER}" >> ${PREFIX}/MANIFEST.txt
