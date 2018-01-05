//
//  KSCrash+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "KSCrash+FWDebug.h"
#import "FWDebugKSCrashInstallationFile.h"

@implementation KSCrash (FWDebug)

+ (void)fwDebugLaunch
{
    FWDebugKSCrashInstallationFile *installation = [FWDebugKSCrashInstallationFile sharedInstance];
    installation.printAppleFormat = YES;
    [installation install];
    
    [KSCrash sharedInstance].deleteBehaviorAfterSendAll = KSCDeleteOnSucess;
    
    [installation sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (completed) {
            NSLog(@"Sent %d reports", (int)[filteredReports count]);
        } else {
            NSLog(@"Failed to send reports: %@", error);
        }
    }];
}

@end
