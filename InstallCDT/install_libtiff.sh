#!/bin/sh
installResources=`pwd`/Resources
scriptResources=$installResources/scripts

productFolder=/Developer/Cocotron/1.0
downloadFolder=$productFolder/Downloads

if [ ""$1"" = "" ];then
  targetPlatform="Windows"
else
  targetPlatform=$1
fi

if [ ""$2"" = "" ];then
  targetArchitecture="i386"
else
  targetArchitecture=$2
fi

if [ ""$3"" = "" ];then
  gccVersion="4.3.1"
else
  gccVersion=$3
fi

BASEDIR=/Developer/Cocotron/1.0/$targetPlatform/$targetArchitecture
PREFIX=`pwd`/../system/i386-mingw32msvc

BUILD=/tmp/build_tiff

TIFFVERSION=4.0.1
$scriptResources/downloadFilesIfNeeded.sh $downloadFolder ftp://ftp.remotesensing.org/pub/libtiff//tiff-${TIFFVERSION}.tar.gz

mkdir -p $BUILD
cd $BUILD
tar -xvzf $downloadFolder/tiff-${TIFFVERSION}.tar.gz
cd tiff-${TIFFVERSION}

pwd 

GCC=$(echo $BASEDIR/gcc-$gccVersion/bin/*gcc)
AS=$(echo $BASEDIR/gcc-$gccVersion/bin/*as)
AR=$(echo $BASEDIR/gcc-$gccVersion/bin/*ar)
RANLIB=$(echo $BASEDIR/gcc-$gccVersion/bin/*ranlib)
TARGET=$($GCC -dumpmachine)

COCOTRON=/Developer/Cocotron/1.0//build/$targetPlatform/$targetArchitecture
INSTALL_PREFIX=$PREFIX/libtiff
BINARY_PATH=$INSTALL_PREFIX/bin
INCLUDE_PATH=$INSTALL_PREFIX/include
LIBRARY_PATH=$INSTALL_PREFIX/lib
export CFLAGS="-DTIF_PLATFORM_CONSOLE"

mkdir -p $BINARY_PATH
mkdir -p $LIBRARY_PATH
mkdir -p $INCLUDE_PATH

./configure --prefix="$INSTALL_PREFIX" -host $TARGET AR=$AR CC=$GCC RANLIB=$RANLIB AS=$AS \
          --with-jpeg-include-dir=$PREFIX/libjpeg/include --with-jpeg-lib-dir=$PREFIX/libjpeg/lib \
          --with-zlib-include-dir=$PREFIX/zlib-1.2.5/include --with-zlib-lib-dir=$PREFIX/zlib-1.2.5/lib \
         --enable-mdi --disable-jpeg12 --disable-cxx --disable-shared 

make && make install

