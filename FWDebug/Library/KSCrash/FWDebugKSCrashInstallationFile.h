//
//  FWDebugKSCrashInstallationFile.h
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSCrashInstallation.h"

@interface FWDebugKSCrashInstallationFile : KSCrashInstallation

@property(nonatomic, assign) BOOL printAppleFormat;

+ (instancetype)sharedInstance;

@end
