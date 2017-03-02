//
//  FWDebugKSCrashReportSinkFile.h
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSCrashReportFilter.h"

@interface FWDebugKSCrashReportSinkFile : NSObject <KSCrashReportFilter>

+ (FWDebugKSCrashReportSinkFile *)filter;

- (id <KSCrashReportFilter>)defaultCrashReportFilterSet;

- (id <KSCrashReportFilter>)defaultCrashReportFilterSetAppleFmt;

@end
