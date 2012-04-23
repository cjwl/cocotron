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

BUILD=/tmp/build_libjepg

mkdir -p $PREFIX

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder http://www.ijg.org/files/jpegsrc.v8c.tar.gz

mkdir -p $BUILD
cd $BUILD
tar -xvzf $downloadFolder/jpegsrc.v8c.tar.gz
cd jpeg-8c

pwd 

GCC=$(echo $BASEDIR/gcc-$gccVersion/bin/*gcc)
RANLIB=$(echo $BASEDIR/gcc-$gccVersion/bin/*ranlib)
TARGET=$($GCC -dumpmachine)


./configure --prefix="$PREFIX" -host $TARGET CC=$GCC RANLIB=$RANLIB

make && make install

