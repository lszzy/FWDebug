//
//  FWDebugAppSecret.m
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugAppConfig.h"
#import "FLEXColor.h"
#import "FWDebugManager+FWDebug.h"
#import "FWDebugTimeProfiler.h"
#import <CommonCrypto/CommonDigest.h>

static BOOL isAppLocked = NO;

@interface FWDebugAppConfig ()

@end

@implementation FWDebugAppConfig

#pragma mark - Static

+ (void)fwDebugLaunch
{
    if ([self isSecretEnabled]) {
        if ([UIApplication sharedApplication].keyWindow != nil) {
            [FWDebugAppConfig secretPrompt];
        }
    }
    
    if ([self isInjectionEnabled]) {
#if TARGET_OS_SIMULATOR
        // https://itunes.apple.com/cn/app/injectioniii/id1380446739?mt=12
        [[NSBundle bundleWithPath:@"/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle"] load];
#endif
    }
}

+ (BOOL)isAppLocked
{
    return isAppLocked;
}

+ (void)secretPrompt
{
    static UIWindow *keyWindow = nil;
    static UIWindow *secretWindow = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyWindow = [UIApplication sharedApplication].keyWindow;
        secretWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        secretWindow.backgroundColor = FLEXColor.primaryBackgroundColor;
        secretWindow.rootViewController = [[UIViewController alloc] init];
        
        [keyWindow resignKeyWindow];
        [secretWindow makeKeyAndVisible];
        
        isAppLocked = YES;
    });
    
    [FWDebugManager fwDebugShowPrompt:secretWindow.rootViewController security:YES title:@"Input Password" message:nil text:nil block:^(BOOL confirm, NSString *text) {
        NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugAppSecret"];
        if (confirm && [secret isEqualToString:[FWDebugAppConfig secretMd5:text]]) {
            [secretWindow resignKeyWindow];
            [keyWindow makeKeyAndVisible];
            
            [secretWindow removeFromSuperview];
            secretWindow = nil;
            keyWindow = nil;
            
            isAppLocked = NO;
        } else {
            [FWDebugAppConfig secretPrompt];
        }
    }];
}

+ (BOOL)isSecretEnabled
{
    NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugAppSecret"];
    return secret && secret.length > 0;
}

+ (BOOL)filterSystemLog
{
    NSNumber *filter = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFilterSystemLog"];
    return filter ? [filter boolValue] : NO;
}

+ (BOOL)traceVCLife
{
    NSNumber *trace = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugTraceVCLife"];
    return trace ? [trace boolValue] : YES;
}

+ (BOOL)traceVCRequest
{
    NSNumber *trace = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugTraceVCRequest"];
    return trace ? [trace boolValue] : NO;
}

+ (NSString *)traceVCUrls
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugTraceVCUrls"];
}

+ (NSInteger)retainCycleDepth
{
    NSNumber *depth = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugRetainCycleDepth"];
    return depth ? [depth integerValue] : 10;
}

+ (BOOL)isInjectionEnabled
{
#if TARGET_OS_SIMULATOR
    NSNumber *injection = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugInjectionEnabled"];
    return injection ? [injection boolValue] : NO;
#endif
    return NO;
}

+ (NSString *)secretMd5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"App Config";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        return 3;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"App Secret";
    } else if (section == 1) {
        return @"InjectionIII Config";
    } else if (section == 2) {
        return @"Time Option";
    } else {
        return @"App Option";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || indexPath.section == 1 ||
        (indexPath.section == 2 && indexPath.row == 0) ||
        (indexPath.section == 2 && indexPath.row == 1) ||
        (indexPath.section == 3 && indexPath.row == 0)) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell1"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell1"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
            accessoryView.userInteractionEnabled = NO;
            cell.accessoryView = accessoryView;
        }
        [self configSwitch:cell indexPath:indexPath];
        return cell;
    } else if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell2"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell2"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
            cell.detailTextLabel.textColor = FLEXColor.deemphasizedTextColor;
            cell.detailTextLabel.numberOfLines = 0;
        }
        [self configLabel:cell indexPath:indexPath];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell3"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell3"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
            cell.detailTextLabel.textColor = FLEXColor.primaryTextColor;
        }
        [self configLabel:cell indexPath:indexPath];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 || indexPath.section == 1 ||
        (indexPath.section == 2 && indexPath.row == 0) ||
        (indexPath.section == 2 && indexPath.row == 1) ||
        (indexPath.section == 3 && indexPath.row == 0)) {
        [self actionSwitch:indexPath];
    } else {
        [self actionLabel:indexPath];
    }
}

- (void)configSwitch:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    if (indexPath.section == 0) {
        if ([self.class isSecretEnabled]) {
            cell.textLabel.text = @"Secret Enabled";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = YES;
        } else {
            cell.textLabel.text = @"Secret Disabled";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = NO;
        }
    } else if (indexPath.section == 1) {
        if ([self.class isInjectionEnabled]) {
            cell.textLabel.text = @"InjectionIII Enabled";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = YES;
        } else {
            cell.textLabel.text = @"InjectionIII Disabled";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = NO;
        }
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        if ([self.class traceVCLife]) {
            cell.textLabel.text = @"Trace VC Life";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = YES;
        } else {
            cell.textLabel.text = @"Trace VC Life";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = NO;
        }
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        if ([self.class traceVCRequest]) {
            cell.textLabel.text = @"Trace VC Request";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = YES;
        } else {
            cell.textLabel.text = @"Trace VC Request";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = NO;
        }
    } else if (indexPath.section == 3 && indexPath.row == 0) {
        if ([self.class filterSystemLog]) {
            cell.textLabel.text = @"Filter System Log";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = YES;
        } else {
            cell.textLabel.text = @"Filter System Log";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = NO;
        }
    }
}

- (void)configLabel:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        cell.textLabel.text = @"Trace VC Url";
        cell.detailTextLabel.text = [[self.class traceVCUrls] stringByReplacingOccurrencesOfString:@";" withString:@";\n"];
    } else if (indexPath.section == 3) {
        cell.textLabel.text = @"Retain Cycle Depth";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", @([self.class retainCycleDepth])];
    }
}

#pragma mark - Action

- (void)actionSwitch:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    
    if (indexPath.section == 0) {
        if (!cellSwitch.on) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:YES title:@"Input Password" message:nil text:nil block:^(BOOL confirm, NSString *text) {
                if (confirm && text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:[FWDebugAppConfig secretMd5:text] forKey:@"FWDebugAppSecret"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                [weakSelf configSwitch:cell indexPath:indexPath];
            }];
        } else {
            if ([self.class isSecretEnabled]) {
                typeof(self) __weak weakSelf = self;
                [FWDebugManager fwDebugShowPrompt:self security:YES title:@"Input Password" message:nil text:nil block:^(BOOL confirm, NSString *text) {
                    NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugAppSecret"];
                    if (confirm && [secret isEqualToString:[FWDebugAppConfig secretMd5:text]]) {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugAppSecret"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    
                    [weakSelf configSwitch:cell indexPath:indexPath];
                }];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugAppSecret"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self configSwitch:cell indexPath:indexPath];
            }
        }
    } else if (indexPath.section == 1) {
#if TARGET_OS_SIMULATOR
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugInjectionEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugInjectionEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
#endif
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugTraceVCLife"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
            [FWDebugTimeProfiler enableTraceVCLife];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:@"FWDebugTraceVCLife"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugTraceVCRequest"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
            [FWDebugTimeProfiler enableTraceVCRequest];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugTraceVCRequest"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    } else if (indexPath.section == 3 && indexPath.row == 0) {
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugFilterSystemLog"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFilterSystemLog"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    }
}

- (void)actionLabel:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 2) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[self.class traceVCUrls] block:^(BOOL confirm, NSString *text) {
            if (confirm) {
                if (text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugTraceVCUrls"];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugTraceVCUrls"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf configLabel:cell indexPath:indexPath];
        }];
    } else if (indexPath.section == 3) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:nil block:^(BOOL confirm, NSString *text) {
            if (confirm && text.length > 0) {
                NSInteger value = [text integerValue];
                if (value > 0 && value <= 10) {
                    [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:@"FWDebugRetainCycleDepth"];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugRetainCycleDepth"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf configLabel:cell indexPath:indexPath];
        }];
    }
}

@end
