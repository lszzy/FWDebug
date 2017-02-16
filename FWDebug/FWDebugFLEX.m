//
//  FWDebugFLEX.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugFLEX.h"

#ifdef DEBUG

#import <FLEX/FLEX.h>
#import <objc/runtime.h>

@implementation UIApplication (FWDebugFLEX)

+ (void)load
{
    // 开启网络调试
    [FLEXManager sharedManager].networkDebuggingEnabled = YES;
    
    // 动态替换方法
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(sendEvent:)),
                                   class_getInstanceMethod(self, @selector(fwInnerSendEvent:))
                                   );
}

- (void)fwInnerSendEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        // 5秒内摇一摇两次
        static NSDate *shakeDate = nil;
        if (shakeDate && fabs([shakeDate timeIntervalSinceNow]) > 1.0 && fabs([shakeDate timeIntervalSinceNow]) < 5.0) {
            [[FLEXManager sharedManager] toggleExplorer];
            shakeDate = nil;
        } else if (!shakeDate || fabs([shakeDate timeIntervalSinceNow]) > 5.0) {
            shakeDate = [NSDate date];
        }
    }
    
    // 调用原始方法
    [self fwInnerSendEvent:event];
}

@end

#endif
