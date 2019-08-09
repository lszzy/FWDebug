//
//  FWDebugAppSecret.m
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugAppConfig.h"
#import "FWDebugManager+FWDebug.h"
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
        secretWindow.backgroundColor = [UIColor whiteColor];
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1;
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"App Secret";
    } else if (section == 1) {
        return @"InjectionIII Config";
    } else {
        return @"App Option";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppConfigCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AppConfigCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    
    if (indexPath.section == 0) {
        UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
        accessoryView.userInteractionEnabled = NO;
        cell.accessoryView = accessoryView;
        
        [self configSwitch:cell indexPath:indexPath];
    } else if (indexPath.section == 1) {
        UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
        accessoryView.userInteractionEnabled = NO;
        cell.accessoryView = accessoryView;
        
        [self configSwitch:cell indexPath:indexPath];
    } else {
        UILabel *accessoryView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
        accessoryView.font = [UIFont systemFontOfSize:14];
        accessoryView.textColor = [UIColor blackColor];
        accessoryView.textAlignment = NSTextAlignmentRight;
        cell.accessoryView = accessoryView;
        
        [self configLabel:cell indexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        [self actionSwitch:indexPath];
    } else if (indexPath.section == 1) {
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
    }
}

- (void)configLabel:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UILabel *cellLabel = (UILabel *)cell.accessoryView;
    if (indexPath.section == 2) {
        cell.detailTextLabel.text = nil;
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Retain Cycle Depth";
            cellLabel.text = [NSString stringWithFormat:@"%@", @([self.class retainCycleDepth])];
        }
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
    }
}

- (void)actionLabel:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 2) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:nil block:^(BOOL confirm, NSString *text) {
            if (confirm && text.length > 0) {
                NSInteger value = [text integerValue];
                if (indexPath.row == 0) {
                    if (value > 0 && value <= 10) {
                        [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:@"FWDebugRetainCycleDepth"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugRetainCycleDepth"];
                    }
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf configLabel:cell indexPath:indexPath];
        }];
    }
}

@end
