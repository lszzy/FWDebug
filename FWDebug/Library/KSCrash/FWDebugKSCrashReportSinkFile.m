//
//  FWDebugKSCrashReportSinkFile.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugKSCrashReportSinkFile.h"
#import "KSCrashReportFilterAppleFmt.h"
#import "KSCrashReportFilterBasic.h"
#import "KSCrashReportFilterJSON.h"
#import "NSError+SimpleConstructor.h"

@implementation FWDebugKSCrashReportSinkFile

+ (FWDebugKSCrashReportSinkFile *)filter
{
    return [[self alloc] init];
}

- (id <KSCrashReportFilter>)defaultCrashReportFilterSet
{
    return [KSCrashReportFilterPipeline filterWithFilters:
            [KSCrashReportFilterJSONEncode filterWithOptions:KSJSONEncodeOptionSorted | KSJSONEncodeOptionPretty],
            self,
            nil];
}

- (id <KSCrashReportFilter>)defaultCrashReportFilterSetAppleFmt
{
    return [KSCrashReportFilterPipeline filterWithFilters:
            [KSCrashReportFilterAppleFmt filterWithReportStyle:KSAppleReportStyleSymbolicatedSideBySide],
            self,
            nil];
}

- (void)filterReports:(NSArray*)reports
         onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 创建FWDebug目录
    NSString *reportPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    if (reportPath) {
        reportPath = [[reportPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"CrashLog"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:reportPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:reportPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
        }
    }
    
    // 检查目录是否存在
    if (!reportPath || ![[NSFileManager defaultManager] fileExistsAtPath:reportPath]) {
        kscrash_callCompletion(onCompletion, reports, NO, [NSError errorWithDomain:[[self class] description]
                                                                              code:0
                                                                       description:@"Cannot create CrashLog directory"]);
        return;
    }
    
    // 按日期命名
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd-HHmmss";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    reportPath = [reportPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Crash-%@", dateString]];
    
    // 写入文件
    int i = 0;
    for (NSString *report in reports) {
        NSString *reportFile = [reportPath stringByAppendingString:[NSString stringWithFormat:@"-%@.log", @(++i)]];
        [report writeToFile:reportFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    
    kscrash_callCompletion(onCompletion, reports, YES, nil);
}

@end
