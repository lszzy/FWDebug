#!/bin/sh

#自定义配置
DYNAMIC_TARGET="FWDebug"
DYNAMIC_PROJECT="FWDebug.xcodeproj"
DYNAMIC_BUILD="FWDebug"

#环境配置，支持"Debug Release"
CONFS="Debug Release"

#通用配置
CURRENT=`pwd`
WORKSPACE=$CURRENT
TARGET=$CURRENT/Products
BUILD=$CURRENT/Build

rm -rf $TARGET
rm -rf $BUILD
mkdir $TARGET

cd $WORKSPACE

#动态库
for CONF in $CONFS
do
    xcodebuild -configuration "$CONF" -target "$DYNAMIC_TARGET" -project "$DYNAMIC_PROJECT" -sdk iphonesimulator clean build
    xcodebuild -configuration "$CONF" -target "$DYNAMIC_TARGET" -project "$DYNAMIC_PROJECT" -sdk iphoneos clean build

    mkdir $TARGET/$CONF
    cp -rf "build/$CONF-iphoneos/$DYNAMIC_BUILD.framework" $TARGET/$CONF
    lipo -create "build/$CONF-iphonesimulator/$DYNAMIC_BUILD.framework/$DYNAMIC_BUILD" "build/$CONF-iphoneos/$DYNAMIC_BUILD.framework/$DYNAMIC_BUILD" -output "$TARGET/$CONF/$DYNAMIC_BUILD.framework/$DYNAMIC_BUILD"

    lipo -info "$TARGET/$CONF/$DYNAMIC_BUILD.framework/$DYNAMIC_BUILD"
    rm -rf "$TARGET/$CONF/$DYNAMIC_BUILD.framework/_CodeSignature"
    rm -rf build
done

#拷贝
cp -rf "$TARGET/Release/$DYNAMIC_BUILD.framework" $TARGET

#重命名
mv $TARGET $BUILD

echo "Success."
