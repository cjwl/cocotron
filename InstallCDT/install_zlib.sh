#!/bin/sh
echo "Installing zlib"

installResources=`pwd`/Resources
scriptResources=$installResources/scripts

productFolder=/Developer/Cocotron/1.0
downloadFolder=$productFolder/Downloads

PREFIX=/Developer/Cocotron/1.0/Windows/i386/

# We need the headers/libraries, zlib.net only provides a dll or source which is more work

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "ftp://ftp.zlatkovic.com/libxml/zlib-1.2.5.win32.zip"

mkdir -p $PREFIX
cd $PREFIX
echo `pwd`

unzip -o $downloadFolder/zlib-1.2.5.win32.zip
