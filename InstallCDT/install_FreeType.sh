#!/bin/sh
./install_zlib.sh

installResources=`pwd`/Resources
scriptResources=$installResources/scripts

productFolder=/Developer/Cocotron/1.0
downloadFolder=$productFolder/Downloads

PREFIX=/Developer/Cocotron/1.0/Windows/i386/freetype-2.3.5

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "http://downloads.sourceforge.net/gnuwin32/freetype-2.3.5-1-bin.zip"

mkdir -p $PREFIX
cd $PREFIX

unzip -o $downloadFolder/freetype-2.3.5-1-bin.zip
