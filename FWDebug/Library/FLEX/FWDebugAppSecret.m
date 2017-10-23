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
    
    [FWDebugAppSecret showPrompt:secretWindow.rootViewController title:@"Input Password" message:nil block:^(BOOL confirm, NSString *text) {
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

+ (void)showPrompt:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message block:(void (^)(BOOL confirm, NSString *text))block
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"App Secret";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"AppSecretCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        
        UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
        [accessoryView addTarget:self action:@selector(actionSwitch:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = accessoryView;
    }
    
    [self configCell:cell indexPath:indexPath];
    
    return cell;
}

- (void)configCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    cellSwitch.tag = indexPath.section;
    
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

#pragma mark - Action
- (void)actionSwitch:(UISwitch *)sender {
    if (sender.on) {
        typeof(self) __weak weakSelf = self;
        [FWDebugAppSecret showPrompt:self title:@"Input Password" message:nil block:^(BOOL confirm, NSString *text) {
            if (confirm && text.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:[FWDebugAppSecret secretMd5:text] forKey:@"FWDebugAppSecret"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:sender.tag];
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
            [weakSelf configCell:cell indexPath:indexPath];
        }];
    } else {
        if ([self.class isSecretEnabled]) {
            typeof(self) __weak weakSelf = self;
            [FWDebugAppSecret showPrompt:self title:@"Input Password" message:nil block:^(BOOL confirm, NSString *text) {
                NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugAppSecret"];
                if (confirm && [secret isEqualToString:[FWDebugAppSecret secretMd5:text]]) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugAppSecret"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:sender.tag];
                UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
                [weakSelf configCell:cell indexPath:indexPath];
            }];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugAppSecret"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:sender.tag];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self configCell:cell indexPath:indexPath];
        }
    }
}

@end
