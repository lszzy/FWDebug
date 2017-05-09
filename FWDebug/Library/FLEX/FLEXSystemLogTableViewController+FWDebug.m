//
//  FLEXSystemLogTableViewController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/3/3.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FLEXSystemLogTableViewController+FWDebug.h"
#import "FWDebugFishhook.h"
#import <objc/runtime.h>

@implementation FLEXSystemLogTableViewController (FWDebug)

+ (void)load
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([FWDebugFishhook isLogEnabled]) {
        method_exchangeImplementations(
                                       class_getClassMethod([self class], @selector(allLogMessagesForCurrentProcess)),
                                       class_getClassMethod([self class], @selector(fwDebugAllLogMessagesForCurrentProcess))
                                       );
    }
#pragma clang diagnostic pop
}

+ (NSArray *)fwDebugAllLogMessagesForCurrentProcess
{
    if ([FWDebugFishhook isLogEnabled]) {
        return [FWDebugFishhook allLogMessages];
    } else {
        return [self fwDebugAllLogMessagesForCurrentProcess];
    }
}

@end
