//
//  FWDebugFishhook.m
//  FWDebug
//
//  Created by wuyong on 17/3/5.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugFishhook.h"
#import "FLEXSystemLogMessage.h"
#import "fishhook.h"
#import <objc/runtime.h>

static void (*orig_NSLog)(NSString *format, ...);
static void (*orig_NSLogv)(NSString *format, va_list args);

// 替换NSLog
void fwDebug_NSLog(NSString *format, ...)
{
    va_list args;
    if (format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        orig_NSLog(@"%@", message);
        [FWDebugFishhook logMessage:message];
    }
}

// 替换NSLogv
void fwDebug_NSLogv(NSString *format, va_list args)
{
    va_list copy_args;
    va_copy(copy_args, args);
    orig_NSLogv(format, args);
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:copy_args];
    [FWDebugFishhook logMessage:message];
}

#pragma mark - FWDebugFishhook

static NSMutableArray *_allLogs;

@implementation FWDebugFishhook

+ (void)load
{
    if (![self isLogEnabled]) {
        return;
    }
    
    rcd_rebind_symbols((struct rcd_rebinding[2]){
        {"NSLog", fwDebug_NSLog, (void *)&orig_NSLog},
        {"NSLogv", fwDebug_NSLogv, (void *)&orig_NSLogv}
    }, 2);
}

+ (BOOL)isLogEnabled
{
#ifdef __IPHONE_10_0
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    // Xcode8+真机iOS10系统NSLog不显示，重写NSLog方便调试
    return YES;
#endif
#endif
    return NO;
}

+ (void)logMessage:(NSString *)message
{
    if (![self isLogEnabled]) {
        return;
    }
    
    // 消息为空
    if (!message) {
        return;
    }
    
    // 初始化目录
    static NSString *_logFilePath;
    static dispatch_queue_t _logFileQueue;
    static NSInteger _logCount;
    static NSDateFormatter *_logFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 创建目录
        NSString *logPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        logPath = [[logPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"NSLog"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        // 按日期命名
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyyMMdd-HHmmss";
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        _logFilePath = [logPath stringByAppendingPathComponent:[NSString stringWithFormat:@"NSLog-%@.log", dateString]];
        
        // 文件写队列，串行
        _logFileQueue = dispatch_queue_create("com.ocphp.FWDebugNSLog", DISPATCH_QUEUE_SERIAL);
        
        // 初始化内存缓存
        _allLogs = [NSMutableArray array];
        _logCount = 0;
        _logFormatter = [[NSDateFormatter alloc] init];
        _logFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    });
    
    // 异步写文件
    dispatch_async(_logFileQueue, ^{
        // 写入内存缓存
        FLEXSystemLogMessage *logObj = [[FLEXSystemLogMessage alloc] init];
        logObj.date = [NSDate date];
        logObj.sender = @"FWDebug";
        logObj.messageText = message;
        logObj.messageID = ++_logCount;
        [_allLogs addObject:logObj];
        
        // 追加写入文件
        NSString *fileText = [NSString stringWithFormat:@"%@: %@\n", [_logFormatter stringFromDate:logObj.date], logObj.messageText];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_logFilePath]) {
            // 合并旧日志文件
            [self mergeLogFiles:[_logFilePath stringByDeletingLastPathComponent]];
            // 创建新的文件
            [fileText writeToFile:_logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[fileText dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    });
}

+ (void)mergeLogFiles:(NSString *)logPath
{
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logPath error:nil];
    for (NSString *fileName in fileNames) {
        // 只保留最近7天的日志
        if (fileName.length == 18 && [fileName hasPrefix:@"NSLog-"]) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMdd";
            NSDate *date = [formatter dateFromString:[fileName substringWithRange:NSMakeRange(6, 8)]];
            NSTimeInterval logTime = [date timeIntervalSince1970];
            NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
            if ((nowTime - logTime) >= 86400 * 7) {
                NSString *filePath = [logPath stringByAppendingPathComponent:fileName];
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            continue;
        }
        
        // 只处理未合并的文件
        if (fileName.length != 25 || ![fileName hasPrefix:@"NSLog-"]) continue;
        
        // 写入新文件
        NSString *filePath = [logPath stringByAppendingPathComponent:fileName];
        NSString *mergePath = [logPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log", [fileName substringToIndex:14]]];
        NSString *fileLog = [NSString stringWithFormat:@"\n=====%@=====\n", fileName];
        fileLog = [fileLog stringByAppendingString:[[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:mergePath]) {
            [[NSFileManager defaultManager] createFileAtPath:mergePath contents:[fileLog dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        } else {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:mergePath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[fileLog dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
        
        // 删除原文件
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

+ (NSArray *)allLogMessages
{
    if (![self isLogEnabled]) {
        return nil;
    }
    
    return _allLogs ? [_allLogs copy] : nil;
}

@end
