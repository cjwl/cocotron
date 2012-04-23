#!/bin/sh
#Copyright (c) 2006 Christopher J. W. Lloyd
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this
#software and associated documentation files (the "Software"), to deal in the Software
#without restriction, including without limitation the rights to use, copy, modify,
#merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
#permit persons to whom the Software is furnished to do so, subject to the following
#conditions:
#
#The above copyright notice and this permission notice shall be included in all copies
#or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
#INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
#PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
#OR OTHER DEALINGS IN THE SOFTWARE.
#
# Inspired by the build-cross.sh script by Sam Lantinga, et al
# Usage: install.sh <platform> <architecture> <gcc-version>"
# Windows i386, Linux i386, Solaris sparc

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

if [ ""$4"" = "" ];then
        gccVersionDate="-02242010"
else
	gccVersionDate="-"$4
fi

set -eu

cd "`dirname \"$0\"`"
installResources=`pwd`/Resources

if [ ! -d "$installResources" ];then
 /bin/echo "Unable to locate Resources directory at "$installResources
 exit 1
fi

enableLanguages="c,objc,c++,obj-c++"

installFolder=/Developer
productName=Cocotron
productVersion=1.0

binutilsVersion=2.21-20111025
mingwRuntimeVersion=3.20
mingwAPIVersion=3.17-2
gmpVersion=4.2.3
mpfrVersion=2.3.2

binutilsConfigureFlags=""

if [ $targetPlatform = "Windows" ];then
	if [ $targetArchitecture = "i386" ];then
		compilerTarget=i386-mingw32msvc
		compilerConfigureFlags=""
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
	exit 1
	fi
elif [ $targetPlatform = "Linux" ];then
	if [ $targetArchitecture = "i386" ];then
		compilerTarget=i386-ubuntu-linux
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	elif [ $targetArchitecture = "arm" ];then
		compilerTarget=arm-none-linux-gnueabi
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	elif [ $targetArchitecture = "ppc" ];then
   	 	compilerTarget=powerpc-unknown-linux
    		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	elif [ $targetArchitecture = "x86_64" ];then
		compilerTarget=x86_64-pc-linux
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
		binutilsConfigureFlags="--enable-64-bit-bfd"
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
		exit 1
	fi
elif [ $targetPlatform = "FreeBSD" ];then
	if [ $targetArchitecture = "i386" ];then
		compilerTarget=i386-pc-freebsd7
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
		exit 1
	fi
elif [ $targetPlatform = "Solaris" ];then
	if [ $targetArchitecture = "sparc" ];then
		compilerTarget=sparc-sun-solaris
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
		exit 1
	 fi
else
	/bin/echo "Unsupported platform $targetPlatform"
	exit 1
fi


scriptResources=$installResources/scripts
toolResources=$installResources/tools



productFolder=$installFolder/$productName/$productVersion

downloadFolder=$productFolder/Downloads
sourceFolder=$productFolder/Source
interfaceFolder=$productFolder/PlatformInterfaces/$compilerTarget
buildFolder=$productFolder/build/$targetPlatform/$targetArchitecture
resultFolder=$productFolder/$targetPlatform/$targetArchitecture/gcc-$gccVersion
toolFolder=$productFolder/bin

PATH="$resultFolder/bin:$PATH"

downloadCompilerIfNeeded(){
	$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "http://cocotron-tools-gpl3.googlecode.com/files/gcc-$gccVersion$gccVersionDate.tar.bz2 http://ftp.sunet.se/pub/gnu/gmp/gmp-$gmpVersion.tar.bz2 http://cocotron-binutils-2-21.googlecode.com/files/binutils-$binutilsVersion.tar.gz http://cocotron-tools-gpl3.googlecode.com/files/mpfr-$mpfrVersion.tar.bz2"

	$scriptResources/unarchiveFiles.sh $downloadFolder $sourceFolder "gcc-$gccVersion$gccVersionDate binutils-$binutilsVersion gmp-$gmpVersion mpfr-$mpfrVersion"
}

createWindowsInterfaceIfNeeded(){
	$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "http://cocotron-tools-gpl3.googlecode.com/files/mingwrt-$mingwRuntimeVersion-mingw32-dev.tar.gz http://cocotron-tools-gpl3.googlecode.com/files/w32api-$mingwAPIVersion-mingw32-dev.tar.gz"

	$scriptResources/unarchiveFiles.sh $downloadFolder $interfaceFolder "mingwrt-$mingwRuntimeVersion-mingw32-dev w32api-$mingwAPIVersion-mingw32-dev"
}

createLinuxInterfaceIfNeeded(){
# Interface is created before script execution, see doc.s
/bin/echo "Done."
}

createFreeBSDInterfaceIfNeeded(){
# Interface is created before script execution, see doc.s
/bin/echo "Done."
}

createSolarisInterfaceIfNeeded(){
# Interface is created before script execution, see doc.s
/bin/echo "Done."
}

copyPlatformInterface(){
	if [ ! -d $interfaceFolder ];then
		/bin/echo "Interface (headers, libraries, etc.) not present at "$interfaceFolder", exiting"
		exit 1
	else
		mkdir -p $resultFolder/$compilerTarget
		(cd $interfaceFolder;gnutar -cf - *) | (cd $resultFolder/$compilerTarget;gnutar -xf -)
	fi
}

configureAndInstall_binutils() {
	/bin/echo "Configuring, building and installing binutils "$binutilsVersion
	rm -rf $buildFolder/binutils-$binutilsVersion
	mkdir -p $buildFolder/binutils-$binutilsVersion
	pushd $buildFolder/binutils-$binutilsVersion
	CFLAGS="-m32 -Wformat=0 -Wno-error=deprecated-declarations" $sourceFolder/binutils-$binutilsVersion/configure --prefix="$resultFolder" --target=$compilerTarget $binutilsConfigureFlags
	make
	make install
	popd
}

configureAndInstall_gmpAndMpfr() {
	/bin/echo "Configuring and building and installing gmp "$gmpVersion
	rm -rf $buildFolder/gmp-$gmpVersion
	mkdir -p $buildFolder/gmp-$gmpVersion
	pushd $buildFolder/gmp-$gmpVersion
	ABI=32 $sourceFolder/gmp-$gmpVersion/configure --prefix="$resultFolder"
	make
	make install
	popd
	
    /bin/echo "Configuring and building mpfr "$mpfrVersion
	rm -rf $buildFolder/mpfr-$mpfrVersion
	mkdir -p $buildFolder/mpfr-$mpfrVersion
	pushd $buildFolder/mpfr-$mpfrVersion
	$sourceFolder/mpfr-$mpfrVersion/configure --prefix="$resultFolder" --with-gmp-build=$buildFolder/gmp-$gmpVersion
	make
	make install
	popd
}

configureAndInstall_gcc() {
	/bin/echo "Configuring, building and installing gcc "$gccVersion
	rm -rf $buildFolder/gcc-$gccVersion
	mkdir -p $buildFolder/gcc-$gccVersion
	pushd $buildFolder/gcc-$gccVersion
	CFLAGS="-m32" $sourceFolder/gcc-$gccVersion/configure -v --prefix="$resultFolder" --target=$compilerTarget \
		--with-gnu-as --with-gnu-ld --with-headers=$resultFolder/$compilerTarget/include \
		--without-newlib --disable-multilib --disable-libssp --disable-nls --enable-languages="$enableLanguages" \
		--with-gmp=$buildFolder/gmp-$gmpVersion --enable-decimal-float --with-mpfr=$resultFolder --enable-checking=release \
		--enable-objc-gc \
		$compilerConfigureFlags
	make 
	make install
	popd
}

stripBinaries() {
	/bin/echo -n "Stripping binaries ..."
	for x in `find $resultFolder/bin -type f -print`
	do
		strip $x
	done
	for x in `find $resultFolder/$compilerTarget/bin/ -type f -print`
	do
		strip $x
	done
	for x in `find $resultFolder/libexec/gcc/$compilerTarget/$gccVersion -type f -print`
	do
		strip $x
	done
	/bin/echo "done."
}

"create"$targetPlatform"InterfaceIfNeeded"
downloadCompilerIfNeeded
 
copyPlatformInterface

configureAndInstall_binutils

configureAndInstall_gmpAndMpfr

configureAndInstall_gcc

stripBinaries

/bin/echo -n "Creating specifications ..."
$scriptResources/createSpecifications.sh $targetPlatform $targetArchitecture $productName $productVersion $compilerTarget $installResources/Specifications $gccVersion
/bin/echo "done."

/bin/echo "Building tools ..."
mkdir -p $toolFolder
cc $toolResources/retargetBundle.m -framework Foundation -o $toolFolder/retargetBundle
/bin/echo "done."

(cd $resultFolder/..;ln -fs gcc-$gccVersion g++-$gccVersion)

/bin/echo "Script completed"
