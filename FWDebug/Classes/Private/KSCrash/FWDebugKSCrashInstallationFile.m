//
//  FWDebugKSCrashInstallationFile.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugKSCrashInstallationFile.h"
#import "KSCrashInstallation+Private.h"
#import "KSCrashReportFilterAppleFmt.h"
#import "KSCrashReportFilterBasic.h"
#import "KSCrashReportFilterJSON.h"
#import "KSCrashReportFilterStringify.h"
#import "FWDebugKSCrashReportSinkFile.h"

@implementation FWDebugKSCrashInstallationFile

@synthesize printAppleFormat = _printAppleFormat;

+ (instancetype)sharedInstance
{
    static FWDebugKSCrashInstallationFile *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FWDebugKSCrashInstallationFile alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if ((self = [super initWithRequiredProperties:nil])) {
        self.printAppleFormat = NO;
    }
    return self;
}

- (id<KSCrashReportFilter>)sink
{
    FWDebugKSCrashReportSinkFile *sink = [FWDebugKSCrashReportSinkFile filter];
    if (self.printAppleFormat) {
        return [sink defaultCrashReportFilterSetAppleFmt];
    } else {
        return [sink defaultCrashReportFilterSet];
    }
}

@end
