#!/bin/sh
installResources=`pwd`/Resources
scriptResources=$installResources/scripts

productFolder=/Developer/Cocotron/1.0
downloadFolder=$productFolder/Downloads

PREFIX=/Developer/Cocotron/1.0/Windows/i386/gcc-4.3.1/i386-mingw32msvc/

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "http://cocotron.googlecode.com/files/sqlite-dll-win32-x86-3070600.zip"

TMPDIR=/tmp/install_sqlite$$
echo $TMPDIR
mkdir $TMPDIR
cd $TMPDIR
unzip $downloadFolder/sqlite-dll-win32-x86-3070600.zip

mkdir -p $PREFIX/bin
cp sqlite3.dll $PREFIX/bin

mkdir -p $PREFIX/lib
$PREFIX/bin/dlltool --def sqlite3.def --dllname sqlite3.dll --output-lib $PREFIX/lib/libsqlite3.a