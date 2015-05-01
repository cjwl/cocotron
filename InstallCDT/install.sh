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
# Usage: install.sh <platform> <architecture> <compiler> <compiler-version> <osVersion>"
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
	compiler="gcc"
else
	compiler=$3
fi

gccVersion="4.3.1"

if [ ""$4"" = "" ];then
	if [ "$compiler" = "gcc" ]; then
		compilerVersion=$gccVersion
	elif [ "$compiler" = "llvm-clang" ]; then
		compilerVersion="trunk"
	else
		/bin/echo "Unknown compiler "$compiler
		exit 1
	fi
else
	compilerVersion=$4
fi

if [ ""$5"" = "" ];then
	if [ "$compiler" = "gcc" ]; then
        compilerVersionDate="-02242010"
	elif [ "$compiler" = "llvm-clang" ]; then
        compilerVersionDate="-05042011"
	else
		/bin/echo "Unknown compiler "$compiler
		exit 1
	fi
else
	compilerVersionDate="-"$5
fi

osVersion=$6

if [ ""$6"" = "" ];then
	if [ ""$6"" = "" -a ""$targetPlatform"" = "Solaris" ];then
		osVersion="2.10"
	elif [ ""$6"" = "" -a ""$targetPlatform"" = "FreeBSD" ];then
		osVersion="7"
	else
		osVersion=""
	fi
else
	osVersion=$6
fi

if [ $targetArchitecture = "x86_64" ];then
	wordSize="64"
else
	wordSize="32"
fi

/bin/echo "Welcome to The Cocotron's InstallCDT script"

if [ -w /Library/Application\ Support/Developer/Shared/Xcode/Specifications ];then
	/bin/echo "Permissions properly set up, continuing install."
else
	/bin/echo "For this script to complete successfully, the directory /Library/Application Support/Develper/Shared/Xcode/Specifications must be writeable by you, and we've detected that it isn't.  "
	exit 1
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
		compilerTarget=i386-pc-mingw32msvc$osVersion
		compilerConfigureFlags=""
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
	exit 1
	fi
elif [ $targetPlatform = "Linux" ];then
	if [ $targetArchitecture = "i386" ];then
		compilerTarget=i386-ubuntu-linux$osVersion
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	elif [ $targetArchitecture = "arm" ];then
		compilerTarget=arm-none-linux-gnueabi$osVersion
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	elif [ $targetArchitecture = "ppc" ];then
   	 	compilerTarget=powerpc-unknown-linux$osVersion
    		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	elif [ $targetArchitecture = "x86_64" ];then
		compilerTarget=x86_64-pc-linux$osVersion
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
		binutilsConfigureFlags="--enable-64-bit-bfd"
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
		exit 1
	fi
elif [ $targetPlatform = "FreeBSD" ];then
	if [ $targetArchitecture = "i386" ];then
		compilerTarget=i386-pc-freebsd$osVersion
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	elif [ $targetArchitecture = "x86_64" ];then
		compilerTarget=x86_64-pc-freebsd$osVersion
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
		binutilsConfigureFlags="--enable-64-bit-bfd"
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
		exit 1
	fi
elif [ $targetPlatform = "Solaris" ];then
	if [ $targetArchitecture = "sparc" ];then
		compilerTarget=sparc-sun-solaris$osVersion
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
		exit 1
	 fi
elif [ $targetPlatform = "Darwin" ];then
	if [ $targetArchitecture = "i386" ];then
		compilerTarget=i386-unknown-darwin$osVersion
		compilerConfigureFlags="--enable-version-specific-runtime-libs --enable-shared --enable-threads=posix --disable-checking --disable-libunwind-exceptions --with-system-zlib --enable-__cxa_atexit"
	else
		/bin/echo "Unsupported architecture $targetArchitecture on $targetPlatform"
		exit 1
	 fi

else
	/bin/echo "Unsupported platform $targetPlatform"
	exit 1
fi


scriptResources="$installResources/scripts"
toolResources="$installResources/tools"



productFolder=$installFolder/$productName/$productVersion

downloadFolder=$productFolder/Downloads
sourceFolder=$productFolder/Source
interfaceFolder=$productFolder/PlatformInterfaces/$compilerTarget
buildFolder=$productFolder/build/$targetPlatform/$targetArchitecture
resultFolder=$productFolder/$targetPlatform/$targetArchitecture/$compiler-$compilerVersion
toolFolder=$productFolder/bin

PATH="$resultFolder/bin:$PATH"

downloadCompilerIfNeeded(){
	$scriptResources/downloadFilesIfNeeded.sh $downloadFolder "http://cocotron-tools-gpl3.googlecode.com/files/$compiler-$compilerVersion$compilerVersionDate.tar.bz2 http://ftp.sunet.se/pub/gnu/gmp/gmp-$gmpVersion.tar.bz2 http://cocotron-binutils-2-21.googlecode.com/files/binutils-$binutilsVersion.tar.gz http://cocotron-tools-gpl3.googlecode.com/files/mpfr-$mpfrVersion.tar.bz2"
	$scriptResources/unarchiveFiles.sh $downloadFolder $sourceFolder "$compiler-$compilerVersion$compilerVersionDate binutils-$binutilsVersion gmp-$gmpVersion mpfr-$mpfrVersion"
}

createWindowsInterfaceIfNeeded(){
	"$scriptResources/downloadFilesIfNeeded.sh" $downloadFolder "http://cocotron-tools-gpl3.googlecode.com/files/mingwrt-$mingwRuntimeVersion-mingw32-dev.tar.gz http://cocotron-tools-gpl3.googlecode.com/files/w32api-$mingwAPIVersion-mingw32-dev.tar.gz"

	"$scriptResources/unarchiveFiles.sh" $downloadFolder $interfaceFolder "mingwrt-$mingwRuntimeVersion-mingw32-dev w32api-$mingwAPIVersion-mingw32-dev"
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

createDarwinInterfaceIfNeeded(){
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
	CFLAGS="-m${wordSize} -Wformat=0 -Wno-error=deprecated-declarations" $sourceFolder/binutils-$binutilsVersion/configure --prefix="$resultFolder" --target=$compilerTarget $binutilsConfigureFlags
	make
	make install
	popd
}

configureAndInstall_gmpAndMpfr() {
	/bin/echo "Configuring and building and installing gmp "$gmpVersion
	rm -rf $buildFolder/gmp-$gmpVersion
	mkdir -p $buildFolder/gmp-$gmpVersion
	pushd $buildFolder/gmp-$gmpVersion
	ABI=${wordSize} $sourceFolder/gmp-$gmpVersion/configure --prefix="$resultFolder"
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

configureAndInstall_compiler() {
	/bin/echo "Configuring, building and installing $compiler "$compilerVersion

if [ "$compiler" = "gcc" ]; then	
	rm -rf $buildFolder/$compiler-$compilerVersion
	mkdir -p $buildFolder/$compiler-$compilerVersion
	pushd $buildFolder/$compiler-$compilerVersion

	CFLAGS="-m${wordSize}" $sourceFolder/$compiler-$compilerVersion/configure -v --prefix="$resultFolder" --target=$compilerTarget \
		--with-gnu-as --with-gnu-ld --with-headers=$resultFolder/$compilerTarget/include \
		--without-newlib --disable-multilib --disable-libssp --disable-nls --enable-languages="$enableLanguages" \
		--with-gmp=$buildFolder/gmp-$gmpVersion --enable-decimal-float --with-mpfr=$resultFolder --enable-checking=release \
		--enable-objc-gc \
		$compilerConfigureFlags
	make 
	make install
	popd

elif [ "$compiler" = "llvm-clang" ]; then	
	if [ ! -e "$productFolder/$compiler-$compilerVersion/bin/clang" ]; then
		rm -rf $productFolder/build/$compiler-$compilerVersion
		mkdir -p $productFolder/build/$compiler-$compilerVersion
		pushd $productFolder/build/$compiler-$compilerVersion
		$sourceFolder/$compiler-$compilerVersion/configure --enable-optimized --prefix="$productFolder/$compiler-$compilerVersion"
		make 
		make install
		popd
	else
		/bin/echo "compiler $compiler already exists"
	fi
else
	/bin/echo "Unknown compiler $compiler"
	exit 1
fi

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
    if [ "$compiler" = "gcc" ]; then
	    for x in `find $resultFolder/libexec/$compiler/$compilerTarget/$compilerVersion -type f -print`
	    do
		    strip $x
	    done
	fi
	/bin/echo "done."
}

"create"$targetPlatform"InterfaceIfNeeded"
downloadCompilerIfNeeded
       
/bin/echo -n "Copying the platform interface.  This could take a while.."
if [ $targetPlatform != "Darwin" ]; then
	copyPlatformInterface
fi
/bin/echo -n "done."

configureAndInstall_binutils

configureAndInstall_gmpAndMpfr

configureAndInstall_compiler

stripBinaries

/bin/echo -n "Creating specifications ..."
"$scriptResources/createSpecifications.sh" $targetPlatform $targetArchitecture $productName $productVersion $compilerTarget "$installResources/Specifications"  $compiler $compilerVersion
/bin/echo "done."

/bin/echo "Building tools ..."
mkdir -p $toolFolder
cc "$toolResources/retargetBundle.m" -framework Foundation -o $toolFolder/retargetBundle
/bin/echo "done."

if [ "$compiler" = "gcc" ]; then
	(cd $resultFolder/..;ln -fs $compiler-$compilerVersion g++-$compilerVersion)
elif [ "$compiler" = "llvm-clang" ]; then	
	(cd $resultFolder/..;ln -fs $compiler-$compilerVersion llvm-clang++-$compilerVersion)
else
	/bin/echo "Unknown compiler $compiler"
	exit 1
fi

if [ "$compiler" = "llvm-clang" ]; then
# you need to install also gcc because -ccc-gcc-name is required for cross compiling with clang (this is required for choosing the right assembler 'as' tool. 
# there is no flag for referencing only this tool :-(
/bin/echo -n "Creating clang script for architecture $targetArchitecture ..."
/bin/echo '#!/bin/sh' > $installFolder/$productName/$productVersion/$targetPlatform/$targetArchitecture/llvm-clang-$compilerVersion/bin/$compilerTarget-llvm-clang
/bin/echo "$productFolder/$compiler-$compilerVersion/bin/clang -fcocotron-runtime -ccc-host-triple $compilerTarget -ccc-gcc-name $installFolder/$productName/$productVersion/$targetPlatform/$targetArchitecture/gcc-$gccVersion/bin/$compilerTarget-gcc \
-I$installFolder/$productName/$productVersion/$targetPlatform/$targetArchitecture/llvm-clang-$compilerVersion/$compilerTarget/include \"\$@\"" >> $installFolder/$productName/$productVersion/$targetPlatform/$targetArchitecture/llvm-clang-$compilerVersion/bin/$compilerTarget-llvm-clang
chmod +x $installFolder/$productName/$productVersion/$targetPlatform/$targetArchitecture/llvm-clang-$compilerVersion/bin/$compilerTarget-llvm-clang
/bin/echo "done."
fi
echo 

/bin/echo "Script completed"
