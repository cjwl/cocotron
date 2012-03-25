#!/bin/sh
installResources=`pwd`/Resources
scriptResources=$installResources/scripts

productFolder=/Developer/Cocotron/1.0
downloadFolder=$productFolder/Downloads

PREFIX=/Developer/Cocotron/1.0/Windows/i386/hunspell-1.3.1
BUILD=/tmp/build_hunspell

$scriptResources/downloadFilesIfNeeded.sh $downloadFolder http://downloads.sourceforge.net/hunspell/hunspell-1.3.1.tar.gz

mkdir -p $BUILD
cd $BUILD
tar -xvzf $downloadFolder/hunspell-1.3.1.tar.gz
cd hunspell-1.3.1/src

/Developer/Cocotron/1.0/Windows/i386/g++-4.3.1/bin/i386-mingw32msvc-g++ -shared -O2 -ansi -pedantic hunspell/affentry.cxx hunspell/affixmgr.cxx hunspell/hashmgr.cxx hunspell/suggestmgr.cxx hunspell/csutil.cxx hunspell/phonet.cxx hunspell/hunspell.cxx hunspell/filemgr.cxx hunspell/hunzip.cxx hunspell/replist.cxx parsers/textparser.cxx parsers/firstparser.cxx parsers/htmlparser.cxx parsers/latexparser.cxx parsers/manparser.cxx -Ihunspell -Iwin_api win_api/hunspelldll.c -o hunspell.1.3.1.dll -Wl,--out-implib,libhunspell.1.3.1.a

mkdir -p $PREFIX
mkdir -p $PREFIX/include
mkdir -p $PREFIX/bin
mkdir -p $PREFIX/lib
cp win_api/hunspelldll.h $PREFIX/include
cp hunspell/*.hxx $PREFIX/include
cp hunspell/*.h $PREFIX/include
cp hunspell.1.3.1.dll $PREFIX/bin
cp libhunspell.1.3.1.a $PREFIX/lib

