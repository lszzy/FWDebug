//
//  FWDebugAppSecret.m
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugAppSecret.h"
#import <CommonCrypto/CommonDigest.h>

static BOOL isAppLocked = NO;

@interface FWDebugAppSecret ()

@end

@implementation FWDebugAppSecret

#pragma mark - Static

+ (void)load
{
    if (![self isSecretEnabled]) {
        return;
    }
    
    static NSObject *appObserver = nil;
    appObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:appObserver];
        appObserver = nil;
        
        if ([UIApplication sharedApplication].keyWindow != nil) {
            [FWDebugAppSecret secretPrompt];
        }
    }];
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
    
    [FWDebugAppSecret showPrompt:secretWindow.rootViewController security:YES title:@"Input Password" message:nil block:^(BOOL confirm, NSString *text) {
        NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugAppSecret"];
        if (confirm && [secret isEqualToString:[FWDebugAppSecret secretMd5:text]]) {
            [secretWindow resignKeyWindow];
            [keyWindow makeKeyAndVisible];
            
            [secretWindow removeFromSuperview];
            secretWindow = nil;
            keyWindow = nil;
            
            isAppLocked = NO;
        } else {
            [FWDebugAppSecret secretPrompt];
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

+ (void)showPrompt:(UIViewController *)viewController security:(BOOL)security title:(NSString *)title message:(NSString *)message block:(void (^)(BOOL confirm, NSString *text))block
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = security;
        textField.keyboardType = UIKeyboardTypePhonePad;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (block) {
            block(NO, [alertController.textFields objectAtIndex:0].text);
        }
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (block) {
            block(YES, [alertController.textFields objectAtIndex:0].text);
        }
    }];
    [alertController addAction:alertAction];
    
    [viewController presentViewController:alertController animated:YES completion:nil];
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
    
    self.title = @"App Secret";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"App Secret" : @"Retain Cycle Depth";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = indexPath.section == 0 ? @"AppSecretCell" : @"RetainCycleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        
        if (indexPath.section == 0) {
            UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
            accessoryView.userInteractionEnabled = NO;
            cell.accessoryView = accessoryView;
        } else {
            UILabel *accessoryView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
            accessoryView.font = [UIFont systemFontOfSize:14];
            accessoryView.textColor = [UIColor blackColor];
            cell.accessoryView = accessoryView;
        }
    }
    
    if (indexPath.section == 0) {
        [self configSwitch:cell indexPath:indexPath];
    } else {
        [self configLabel:cell indexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        [self actionSwitch:indexPath];
    } else {
        [self actionLabel:indexPath];
    }
}

- (void)configSwitch:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    if ([self.class isSecretEnabled]) {
        cell.textLabel.text = @"Secret Enabled";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = YES;
    } else {
        cell.textLabel.text = @"Secret Disabled";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = NO;
    }
}

- (void)configLabel:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UILabel *cellLabel = (UILabel *)cell.accessoryView;
    cell.textLabel.text = @"Retain Cycle Depth";
    cell.detailTextLabel.text = nil;
    cellLabel.text = [NSString stringWithFormat:@"%@", @([self.class retainCycleDepth])];
}

#pragma mark - Action

- (void)actionSwitch:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    if (!cellSwitch.on) {
        typeof(self) __weak weakSelf = self;
        [FWDebugAppSecret showPrompt:self security:YES title:@"Input Password" message:nil block:^(BOOL confirm, NSString *text) {
            if (confirm && text.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:[FWDebugAppSecret secretMd5:text] forKey:@"FWDebugAppSecret"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            [weakSelf configSwitch:cell indexPath:indexPath];
        }];
    } else {
        if ([self.class isSecretEnabled]) {
            typeof(self) __weak weakSelf = self;
            [FWDebugAppSecret showPrompt:self security:YES title:@"Input Password" message:nil block:^(BOOL confirm, NSString *text) {
                NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugAppSecret"];
                if (confirm && [secret isEqualToString:[FWDebugAppSecret secretMd5:text]]) {
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
}

- (void)actionLabel:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    typeof(self) __weak weakSelf = self;
    [FWDebugAppSecret showPrompt:self security:NO title:@"Input Depth" message:nil block:^(BOOL confirm, NSString *text) {
        if (confirm && text.length > 0) {
            NSInteger depth = [text integerValue];
            if (depth > 0 && depth <= 10) {
                [[NSUserDefaults standardUserDefaults] setObject:@(depth) forKey:@"FWDebugRetainCycleDepth"];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugRetainCycleDepth"];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        [weakSelf configLabel:cell indexPath:indexPath];
    }];
}

@end
