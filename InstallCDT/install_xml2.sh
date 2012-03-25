#!/bin/sh
echo "Installing libxml2"
./install_zlib.sh

installResources=`pwd`/Resources
scriptResources=$installResources/scripts

productFolder=/Developer/Cocotron/1.0
downloadFolder=$productFolder/Downloads

PREFIX=/Developer/Cocotron/1.0/Windows/i386/

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "ftp://ftp.zlatkovic.com/libxml/libxml2-2.7.7.win32.zip ftp://ftp.zlatkovic.com/libxml/iconv-1.9.2.win32.zip"

mkdir -p $PREFIX
cd $PREFIX
unzip -o $downloadFolder/libxml2-2.7.7.win32.zip
unzip -o $downloadFolder/iconv-1.9.2.win32.zip

