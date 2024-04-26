#!/bin/sh
# 放在与 .xcodeproj 文件同级目录下，编译结果在 build 目录下，输出结果在 Framework 目录下

# 需要编译的 scheme
scheme="FWDebug"

if [ -z "$scheme" ] || [ "$scheme" = "" ]; then
     echo "请填入 scheme 名称"
fi

echo "scheme: $scheme"
cd "$(dirname "$0")" || exit 0

xcodebuild archive \
    -scheme "$scheme" \
    -sdk iphoneos \
    -archivePath "build/iphoneos.xcarchive" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

xcodebuild archive \
    -scheme "$scheme" \
    -sdk iphonesimulator \
    -archivePath "build/iphonesimulator.xcarchive" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

# 优先从 build 文件夹下读取
product_list=$(ls build/iphoneos.xcarchive/Products/Library/Frameworks)
for file_name in $product_list
do
    full_product_name=$file_name
    break
done

# 读取不到就从 showBuildSettings 读取
if [ -z "$full_product_name" ] || [ "$full_product_name" = "" ]; then
    name_dict=$(xcodebuild -showBuildSettings | grep FULL_PRODUCT_NAME)
    full_product_name=${name_dict#*= }
fi

product_name=${full_product_name%.*}

xcodebuild -create-xcframework \
    -framework build/iphoneos.xcarchive/Products/Library/Frameworks/"$full_product_name" \
    -framework build/iphonesimulator.xcarchive/Products/Library/Frameworks/"$full_product_name" \
    -output Framework/"$product_name".xcframework
