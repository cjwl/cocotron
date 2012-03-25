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
set -eu

targetPlatform=$1
targetArchitecture=$2
productName=$3
productVersion=$4
compilerTarget=$5
specificationTemplates=$6
gccVersion=$7

destinationDirectory="/Library/Application Support/Developer/Shared/Xcode/Specifications"
mkdir -p "$destinationDirectory"

uppercaseProductName=`echo $productName | tr "[:lower:]" "[:upper:]"`
uppercasePlatform=`echo $targetPlatform | tr "[:lower:]" "[:upper:]"`
lowercasePlatform=`echo $targetPlatform | tr "[:upper:]" "[:lower:]"`


outputSpecification="$destinationDirectory/$productName-$productVersion-$targetPlatform-$targetArchitecture-gcc"
versionSpecification="$outputSpecification-$gccVersion.pbcompspec"
defaultSpecification="$outputSpecification-default.pbcompspec"

sed -e 's/%REPLACE%Platform%REPLACE%/'$targetPlatform'/g' < $specificationTemplates/gcc-$gccVersion.pbcompspec | \
sed -e 's/%REPLACE%platform%REPLACE%/'$lowercasePlatform'/g'  | \
sed -e 's/%REPLACE%PLATFORM%REPLACE%/'$uppercasePlatform'/g'  | \
sed -e 's/%REPLACE%architecture%REPLACE%/'$targetArchitecture'/g' | \
sed -e 's/%REPLACE%ProductName%REPLACE%/'$productName'/g' | \
sed -e 's/%REPLACE%PRODUCTNAME%REPLACE%/'$uppercaseProductName'/g' | \
sed -e 's/%REPLACE%ProductVersion%REPLACE%/'$productVersion'/g' | \
sed -e 's/%REPLACE%gccVersion%REPLACE%/'$gccVersion'/g' | \
sed -e 's/%REPLACE%TARGET%REPLACE%/'$compilerTarget'/g' > "$versionSpecification"

sed -e 's/%REPLACE%Platform%REPLACE%/'$targetPlatform'/g' < $specificationTemplates/gcc-default.pbcompspec | \
sed -e 's/%REPLACE%platform%REPLACE%/'$lowercasePlatform'/g'  | \
sed -e 's/%REPLACE%PLATFORM%REPLACE%/'$uppercasePlatform'/g'  | \
sed -e 's/%REPLACE%architecture%REPLACE%/'$targetArchitecture'/g' | \
sed -e 's/%REPLACE%ProductName%REPLACE%/'$productName'/g' | \
sed -e 's/%REPLACE%PRODUCTNAME%REPLACE%/'$uppercaseProductName'/g' | \
sed -e 's/%REPLACE%ProductVersion%REPLACE%/'$productVersion'/g' | \
sed -e 's/%REPLACE%gccVersion%REPLACE%/'$gccVersion'/g' | \
sed -e 's/%REPLACE%TARGET%REPLACE%/'$compilerTarget'/g' > "$defaultSpecification"

if [ $targetPlatform = "Windows" ];then
 cp $specificationTemplates/Windows.pbfilespec "$destinationDirectory/$productName-$productVersion-Windows.pbfilespec"
fi
