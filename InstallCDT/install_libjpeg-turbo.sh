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
PREFIX=$BASEDIR/libjpeg

BUILD=/tmp/build_libjepgturbo

mkdir -p $PREFIX


$scriptResources/downloadFilesIfNeeded.sh $downloadFolder http://freefr.dl.sourceforge.net/project/libjpeg-turbo/1.2.0/libjpeg-turbo-1.2.0.tar.gz

mkdir -p $BUILD
cd $BUILD
tar -xvzf $downloadFolder/libjpeg-turbo-1.2.0.tar.gz
cd libjpeg-turbo*

pwd 

GCC=$(echo $BASEDIR/gcc-$gccVersion/bin/*gcc)
AS=$(echo $BASEDIR/gcc-$gccVersion/bin/*as)
AR=$(echo $BASEDIR/gcc-$gccVersion/bin/*ar)
RANLIB=$(echo $BASEDIR/gcc-$gccVersion/bin/*ranlib)
TARGET=$($GCC -dumpmachine)


./configure --prefix="$PREFIX" -host $TARGET AR=$AR AS=$AS CC=$GCC RANLIB=$RANLIB --with-jpeg8 

make && make install
