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

BUILD=/tmp/build_zlib

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder http://freefr.dl.sourceforge.net/project/libpng/zlib/1.2.5/zlib-1.2.5.tar.bz2

mkdir -p $BUILD
cd $BUILD
tar -xvjf $downloadFolder/zlib-1.2.5.tar.bz2
cd zlib-1.2.5

pwd 

GCC=$(echo $BASEDIR/gcc-$gccVersion/bin/*gcc)
RANLIB=$(echo $BASEDIR/gcc-$gccVersion/bin/*ranlib)
AR=$(echo $BASEDIR/gcc-$gccVersion/bin/*ar)


COCOTRON=/Developer/Cocotron/1.0//build/$targetPlatform/$targetArchitecture
INSTALL_PREFIX=/Developer/Cocotron/1.0/Windows/i386/zlib-1.2.5/
BINARY_PATH=$INSTALL_PREFIX/bin
INCLUDE_PATH=$INSTALL_PREFIX/include
LIBRARY_PATH=$INSTALL_PREFIX/lib


make -p $BINARY_PATH
make -p $LIBRARY_PATH
make -p $INCLUDE_PATH

PATH=$COCOTRON/binutils-2.19/binutils:$PATH make -f win32/Makefile.gcc  CC=$GCC AR=$AR RANLIB=$RANLIB RCFLAGS="-I /Developer/Cocotron/1.0/PlatformInterfaces/i386-mingw32msvc/include -DGCC_WINDRES" BINARY_PATH=$BINARY_PATH INCLUDE_PATH=$INCLUDE_PATH LIBRARY_PATH=$LIBRARY_PATH SHARED_MODE=1 install

