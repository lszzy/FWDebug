//
//  NSBundle+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/3/9.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "NSBundle+FWDebug.h"
#import <objc/runtime.h>
#import "JPEngine.h"
#import "GCDWebUploader.h"
#import "JPEngine+FWDebug.h"
#import "FWDebugWebBundle.h"

@implementation NSBundle (FWDebug)

+ (void)load
{
    method_exchangeImplementations(
                                   class_getClassMethod([self class], @selector(bundleForClass:)),
                                   class_getClassMethod([self class], @selector(fwDebugBundleForClass:))
                                   );
}

+ (NSBundle *)fwDebugBundleForClass:(Class)aClass
{
    NSBundle *bundle = [self fwDebugBundleForClass:aClass];
    
    // 处理bundle资源问题
    if (aClass == [JPEngine class]) {
        NSBundle *currentBundle = [NSBundle bundleForClass:[FWDebugWebBundle class]];
        if ([currentBundle.bundlePath isEqualToString:bundle.bundlePath]) {
            NSString *bundlePath = [JPEngine fwDebugBundlePath];
            return [NSBundle bundleWithPath:bundlePath];
        }
    } else if (aClass == [GCDWebUploader class]) {
        NSBundle *currentBundle = [NSBundle bundleForClass:[FWDebugWebBundle class]];
        if ([currentBundle.bundlePath isEqualToString:bundle.bundlePath]) {
            NSString *bundlePath = [FWDebugWebBundle fwDebugBundlePath];
            return [NSBundle bundleWithPath:bundlePath];
        }
    }
    
    return bundle;
}

@end
