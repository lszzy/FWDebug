//
//  FLEXOSLogController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 21/5/26.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXOSLogController+FWDebug.h"
#import "FWDebugManager+FWDebug.h"
#import "FWDebugAppConfig.h"

@interface FLEXOSLogController ()

@property (nonatomic) BOOL canPrint;
@property (nonatomic) int filterPid;
- (BOOL)handleStreamEntry:(os_activity_stream_entry_t)entry error:(int)error;

@end

@implementation FLEXOSLogController (FWDebug)

+ (void)fwDebugLoad
{
    [FWDebugManager swizzleMethod:@selector(handleStreamEntry:error:) in:[FLEXOSLogController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^BOOL(__unsafe_unretained FLEXOSLogController *selfObject, os_activity_stream_entry_t entry, int error) {
            if ([FWDebugAppConfig filterSystemLog] &&
                [selfObject fwDebugHandleStreamEntry:entry error:error]) {
                return YES;
            }
            
            BOOL handleResult = ((BOOL (*)(id, SEL, os_activity_stream_entry_t, int))originalIMP())(selfObject, originalCMD, entry, error);
            return handleResult;
        };
    }];
}

- (BOOL)fwDebugHandleStreamEntry:(os_activity_stream_entry_t)entry error:(int)error {
    if (!self.canPrint || (self.filterPid != -1 && entry->pid != self.filterPid)) {
        return YES;
    }

    if (!error && entry) {
        if (entry->type == OS_ACTIVITY_STREAM_TYPE_LOG_MESSAGE ||
            entry->type == OS_ACTIVITY_STREAM_TYPE_LEGACY_LOG_MESSAGE) {
            os_log_message_t log_message = &entry->log_message;
            
            NSString *imagePath = log_message->image_path ? [NSString stringWithUTF8String:log_message->image_path] : nil;
            if (!imagePath || ![imagePath hasPrefix:NSBundle.mainBundle.bundlePath]) {
                return YES;
            }
        }
    }
    
    return NO;
}

@end
