Tool(s) for building GNU Radio for Android.

# grand-build
A shell script that packages up all of the steps to build the required dependencies as well as VOLK, GNU Radio, GRAnd, and gr-osmosdr.

For more details, see the GNU Radio [Android Page](http://gnuradio.org/redmine/projects/gnuradio/wiki/Android) or specifically the [Instructions to build the dependencies](http://gnuradio.org/redmine/projects/gnuradio/wiki/GRAndDeps) as well as [Instructions to build GNU Radio](http://gnuradio.org/redmine/projects/gnuradio/wiki/GRAndBuild).

It is tested with Ubuntu 15.10, 64-bit. There are likely a handful of apt-gettable programs necessary for this to complete. You will definitely need the following:
- cmake
- git
- make
- xutils-dev
- automake
- autoconf
- libtool
- wget
- perl
- tar
- sed
