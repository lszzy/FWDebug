//
//  KSCrash+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "KSCrash+FWDebug.h"
#import "KSCrashInstallationStandard.h"
#import "KSCrashInstallationEmail.h"
#import "KSCrashInstallation+Alert.h"
#import "FWDebugManager.h"
#import "FWDebugKSCrashInstallationFile.h"

@implementation KSCrash (FWDebug)

+ (void)fwDebugLaunch
{
    FWDebugKSCrashInstallationFile *installation = [FWDebugKSCrashInstallationFile sharedInstance];
    installation.printAppleFormat = YES;
    [installation install];
    
    NSString *crashReporter = FWDebugManager.sharedInstance.crashReporter;
    [KSCrash sharedInstance].deleteBehaviorAfterSendAll = crashReporter ? KSCDeleteNever : KSCDeleteOnSucess;
    [installation sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (completed && filteredReports.count < 1) return;
        if (completed) {
            NSLog(@"FWDebug: Log %d reports", (int)[filteredReports count]);
        } else {
            NSLog(@"FWDebug: Failed to log reports: %@", error);
        }
        if (!crashReporter) return;
        
        KSCrashInstallation *installation = nil;
        if ([crashReporter hasPrefix:@"http"]) {
            KSCrashInstallationStandard *installationStandard = [KSCrashInstallationStandard sharedInstance];
            installationStandard.url = [NSURL URLWithString:crashReporter];
            [installationStandard install];
            installation = installationStandard;
            [KSCrash sharedInstance].deleteBehaviorAfterSendAll = KSCDeleteOnSucess;
        } else if ([crashReporter containsString:@"@"]) {
            KSCrashInstallationEmail *installationEmail = [KSCrashInstallationEmail sharedInstance];
            installationEmail.recipients = [crashReporter componentsSeparatedByString:@";"];
            [installationEmail setReportStyle:KSCrashEmailReportStyleApple useDefaultFilenameFormat:YES];
            [installationEmail addConditionalAlertWithTitle:@"Crash Detected" message:@"The app crashed last time it was launched. Send a crash report?" yesAnswer:@"Sure!" noAnswer:@"No thanks"];
            [installationEmail install];
            installation = installationEmail;
            [KSCrash sharedInstance].deleteBehaviorAfterSendAll = KSCDeleteAlways;
        }
        if (!installation) return;
        
        [installation sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
            if (completed) {
                NSLog(@"FWDebug: Sent %d reports", (int)[filteredReports count]);
            } else {
                NSLog(@"FWDebug: Failed to send reports: %@", error);
            }
        }];
    }];
}

@end
