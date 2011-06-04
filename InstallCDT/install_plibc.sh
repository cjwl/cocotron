#!/bin/sh
installResources=`pwd`/Resources
scriptResources=$installResources/scripts

productFolder=/Developer/Cocotron/1.0
downloadFolder=$productFolder/Downloads

PREFIX=/Developer/Cocotron/1.0/Windows/i386/gcc-4.3.1/i386-mingw32msvc/
INCLUDE=$PREFIX/include
BIN=$PREFIX/bin
LIB=$PREFIX/lib

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "http://sourceforge.net/projects/plibc/files/plibc/0.1.5/plibc-0.1.5.zip"

TMPDIR=/tmp/install_plibc$$
mkdir $TMPDIR
cd $TMPDIR
unzip $downloadFolder/plibc-0.1.5.zip

mkdir -p $PREFIX/bin
cp bin/libplibc-1.dll  $PREFIX/bin

mkdir -p $PREFIX/lib
cp lib/libplibc.dll.a $PREFIX/lib/libplibc.a

mkdir -p $PREFIX/include
(cd include;tar -cf - *) | (cd $PREFIX/include;tar -xf -)

