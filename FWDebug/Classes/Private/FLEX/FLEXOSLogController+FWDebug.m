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
#import "flex_fishhook.h"
#import <objc/runtime.h>

static void (*orig_NSLog)(NSString *format, ...);
static void (*orig_NSLogv)(NSString *format, va_list args);

NSDateFormatter *fwDebug_dateFormatter(void) {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    });
    return dateFormatter;
}

void fwDebug_NSLog(NSString *format, ...) {
    va_list args;
    if (format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        orig_NSLog(@"%@: %@", [fwDebug_dateFormatter() stringFromDate:[NSDate date]], message);
        
        if ([FWDebugAppConfig hookSystemLog]) {
            [FLEXOSLogController appendMessage:message];
        }
    }
}

void fwDebug_NSLogv(NSString *format, va_list args) {
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    orig_NSLog(@"%@: %@", [fwDebug_dateFormatter() stringFromDate:[NSDate date]], message);
    
    if ([FWDebugAppConfig hookSystemLog]) {
        [FLEXOSLogController appendMessage:message];
    }
}

@interface FLEXOSLogController ()

+ (FLEXOSLogController *)sharedLogController;
@property (nonatomic) BOOL canPrint;
@property (nonatomic) int filterPid;
@property (nonatomic) void (^updateHandler)(NSArray<FLEXSystemLogMessage *> *);
- (BOOL)handleStreamEntry:(os_activity_stream_entry_t)entry error:(int)error;

@end

@implementation FLEXOSLogController (FWDebug)

+ (void)fwDebugLoad {
    if ([FWDebugAppConfig hookSystemLog]) {
        [self swizzleSystemLog];
    }
    
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

+ (void)swizzleSystemLog {
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 170000
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        flex_rebind_symbols((struct rebinding[2]){
            {"NSLog", (void *)fwDebug_NSLog, (void **)&orig_NSLog},
            {"NSLogv", (void *)fwDebug_NSLogv, (void **)&orig_NSLogv}
        }, 2);
    });
    #endif
}

+ (void)appendMessage:(NSString *)msg {
    NSDate *date = [[NSDate alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
        FLEXSystemLogMessage *message = [FLEXSystemLogMessage logMessageFromDate:date text:msg];
        if (FLEXOSLogController.sharedLogController.persistent) {
            [FLEXOSLogController.sharedLogController.messages addObject:message];
        }
        if (FLEXOSLogController.sharedLogController.updateHandler) {
            FLEXOSLogController.sharedLogController.updateHandler(@[message]);
        }
    });
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
