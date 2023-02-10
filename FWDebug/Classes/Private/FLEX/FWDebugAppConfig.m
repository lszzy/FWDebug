//
//  FWDebugAppSecret.m
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugAppConfig.h"
#import "FLEXColor.h"
#import "FLEXObjectExplorer.h"
#import "FWDebugManager+FWDebug.h"
#import "FWDebugTimeProfiler.h"
#import <CommonCrypto/CommonDigest.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

static BOOL isAppLocked = NO;
static BOOL filterSystemLog = NO;
static BOOL traceVCLife = NO;
static BOOL traceVCRequest = NO;

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
    
    if ([self webViewNetworkEnabled]) {
        [FWDebugAppConfig registerURLProtocolScheme:@"https"];
        [FWDebugAppConfig registerURLProtocolScheme:@"http"];
    }
    
    if ([self webViewInjectionEnabled]) {
        [FWDebugAppConfig webViewInjectVConsole];
    }
    
    if ([self webViewJavascriptString].length > 0) {
        [FWDebugAppConfig webViewInjectJavascript];
    }
    
    FLEXObjectExplorer.reflexAvailable = [self isReflexEnabled];
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
    
    [FWDebugManager showPrompt:secretWindow.rootViewController security:YES title:@"Input Password" message:nil text:nil block:^(BOOL confirm, NSString *text) {
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
    NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugAppSecret"];
    return value && value.length > 0;
}

+ (BOOL)isReflexEnabled
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugReflexEnabled"];
    return value ? value.boolValue : FLEXObjectExplorer.reflexAvailable;
}

+ (BOOL)filterSystemLog
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFilterSystemLog"];
        filterSystemLog = value ? [value boolValue] : YES;
    });
    return filterSystemLog;
}

+ (BOOL)traceVCLife
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugTraceVCLife"];
        traceVCLife = value ? [value boolValue] : YES;
    });
    return traceVCLife;
}

+ (BOOL)traceVCRequest
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugTraceVCRequest"];
        traceVCRequest = value ? [value boolValue] : NO;
    });
    return traceVCRequest;
}

+ (NSString *)traceVCUrls
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugTraceVCUrls"];
}

+ (NSInteger)retainCycleDepth
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugRetainCycleDepth"];
    return value ? [value integerValue] : 10;
}

+ (BOOL)isInjectionEnabled
{
#if TARGET_OS_SIMULATOR
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugInjectionEnabled"];
    return value ? [value boolValue] : NO;
#endif
    return NO;
}

+ (BOOL)webViewNetworkEnabled
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugWebViewNetworkEnabled"];
    return value ? [value boolValue] : NO;
}

+ (BOOL)webViewInjectionEnabled
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugWebViewInjectionEnabled"];
    return value ? [value boolValue] : NO;
}

+ (NSString *)webViewJavascriptString
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:@"FWDebugWebViewInjectionJavascript"];
    return value ?: @"";
}

+ (Class)urlProtocolContextControllerClass
{
    static Class cls;
    if (!cls) {
        if (@available(iOS 8.0, *)) {
            cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
        }
    }
    return cls;
}

+ (void)registerURLProtocolScheme:(NSString *)scheme
{
    Class cls = [self urlProtocolContextControllerClass];
    SEL sel = NSSelectorFromString(@"registerSchemeForCustomProtocol:");
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)unregisterURLProtocolScheme:(NSString *)scheme
{
    Class cls = [self urlProtocolContextControllerClass];
    SEL sel = NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)webViewInjectVConsole
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager swizzleMethod:@selector(setUserContentController:) in:[WKWebViewConfiguration class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(__unsafe_unretained WKWebViewConfiguration *selfObject, WKUserContentController *userContentController) {
                ((void (*)(id, SEL, WKUserContentController *))originalIMP())(selfObject, originalCMD, userContentController);
                if (![FWDebugAppConfig webViewInjectionEnabled]) return;
                BOOL hasInjection = [objc_getAssociatedObject(userContentController, @selector(webViewInjectVConsole)) boolValue];
                if (hasInjection) return;
                
                NSString *vConsoleFile = [[NSBundle bundleForClass:[FWDebugAppConfig class]] pathForResource:@"GCDWebUploader.bundle/Contents/Resources/js/vconsole.min.js" ofType:nil];
                if (vConsoleFile.length < 1) return;
                NSString *vConsoleJs = [NSString stringWithContentsOfFile:vConsoleFile encoding:NSUTF8StringEncoding error:nil];
                if (vConsoleJs.length < 1) return;
                
                NSString *sourceJs = [vConsoleJs stringByAppendingString:@"if(typeof(VConsole)!='undefined'&&typeof(vConsole)=='undefined'){var vConsole=new VConsole();}"];
                WKUserScript *userScript = [[WKUserScript alloc] initWithSource:sourceJs injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                [userContentController addUserScript:userScript];
                objc_setAssociatedObject(userContentController, @selector(webViewInjectVConsole), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            };
        }];
    });
}

+ (void)webViewInjectJavascript
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager swizzleMethod:@selector(setUserContentController:) in:[WKWebViewConfiguration class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(__unsafe_unretained WKWebViewConfiguration *selfObject, WKUserContentController *userContentController) {
                ((void (*)(id, SEL, WKUserContentController *))originalIMP())(selfObject, originalCMD, userContentController);
                NSString *sourceJs = [FWDebugAppConfig webViewJavascriptString];
                if (sourceJs.length < 1) return;
                BOOL hasInjection = [objc_getAssociatedObject(userContentController, @selector(webViewInjectJavascript)) boolValue];
                if (hasInjection) return;
                
                WKUserScript *userScript = [[WKUserScript alloc] initWithSource:sourceJs injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                [userContentController addUserScript:userScript];
                objc_setAssociatedObject(userContentController, @selector(webViewInjectJavascript), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            };
        }];
    });
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

+ (void)logFile:(NSString *)message
{
    if (message.length < 1) return;
    
    static NSString *_logFilePath;
    static dispatch_queue_t _logFileQueue;
    static NSDateFormatter *_logFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *logPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        logPath = [[logPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"CustomLog"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyyMMdd-HHmmss";
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        _logFilePath = [logPath stringByAppendingPathComponent:[NSString stringWithFormat:@"FWDebug-%@.log", dateString]];
        
        _logFileQueue = dispatch_queue_create("site.wuyong.FWDebug.CustomLog", DISPATCH_QUEUE_SERIAL);
        _logFormatter = [[NSDateFormatter alloc] init];
        _logFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _logFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    });
    
    dispatch_async(_logFileQueue, ^{
        NSString *fileText = [NSString stringWithFormat:@"%@: %@\n", [_logFormatter stringFromDate:[NSDate date]], message];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_logFilePath]) {
            [fileText writeToFile:_logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[fileText dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    });
}

+ (void)mergeLogFiles:(NSString *)logPath
{
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logPath error:nil];
    for (NSString *fileName in fileNames) {
        if (fileName.length == 18 && [fileName hasPrefix:@"FWDebug-"]) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyyMMdd";
            NSDate *date = [formatter dateFromString:[fileName substringWithRange:NSMakeRange(6, 8)]];
            NSTimeInterval logTime = [date timeIntervalSince1970];
            NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
            if ((nowTime - logTime) >= 86400 * 7) {
                NSString *filePath = [logPath stringByAppendingPathComponent:fileName];
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            continue;
        }
        
        if (fileName.length != 25 || ![fileName hasPrefix:@"FWDebug-"]) continue;
        
        NSString *filePath = [logPath stringByAppendingPathComponent:fileName];
        NSString *mergePath = [logPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log", [fileName substringToIndex:14]]];
        NSString *fileLog = [NSString stringWithFormat:@"\n=====%@=====\n", fileName];
        fileLog = [fileLog stringByAppendingString:[[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:mergePath]) {
            [[NSFileManager defaultManager] createFileAtPath:mergePath contents:[fileLog dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        } else {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:mergePath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[fileLog dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"App Config";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 3;
    } else if (section == 1) {
        return 4;
    } else {
        return 5;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Time Option";
    } else if (section == 1) {
        return @"WKWebView Option";
    } else {
        return @"App Option";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2) {
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
    } else if ((indexPath.section == 2 && indexPath.row == 4) ||
               (indexPath.section == 1 && indexPath.row == 3)) {
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
    } else {
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
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ((indexPath.section == 0 && indexPath.row == 2) ||
        (indexPath.section == 2 && indexPath.row == 4) ||
        (indexPath.section == 1 && indexPath.row == 3)) {
        [self actionLabel:indexPath];
    } else {
        [self actionSwitch:indexPath];
    }
}

- (void)configSwitch:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = @"Trace VC Life";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class traceVCLife];
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        cell.textLabel.text = @"Trace VC Request";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class traceVCRequest];
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        cell.textLabel.text = @"Network Debugging";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class webViewNetworkEnabled];
    } else if (indexPath.section == 1 && indexPath.row == 1) {
        cell.textLabel.text = @"Inject vConsole";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class webViewInjectionEnabled];
    } else if (indexPath.section == 1 && indexPath.row == 2) {
        cell.textLabel.text = @"Inject Javascript";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class webViewJavascriptString].length > 0;
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        cell.textLabel.text = @"Filter System Log";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class filterSystemLog];
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        cell.textLabel.text = @"Inspect Swift Objects";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class isReflexEnabled];
    } else if (indexPath.section == 2 && indexPath.row == 2) {
        cell.textLabel.text = @"App Launch Secret";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class isSecretEnabled];
    } else if (indexPath.section == 2 && indexPath.row == 3) {
        cell.textLabel.text = @"Load Simulator InjectionIII";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = [self.class isInjectionEnabled];
    }
}

- (void)configLabel:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Trace VC Url";
        cell.detailTextLabel.text = [[self.class traceVCUrls] stringByReplacingOccurrencesOfString:@";" withString:@";\n"];
    } else if (indexPath.section == 2 && indexPath.row == 4) {
        cell.textLabel.text = @"Retain Cycle Depth";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", @([self.class retainCycleDepth])];
    } else if (indexPath.section == 1 && indexPath.row == 3) {
        cell.textLabel.text = @"Clear WebView Cache";
        cell.detailTextLabel.text = @"";
    }
}

#pragma mark - Action

- (void)actionSwitch:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        if (!cellSwitch.on) {
            traceVCLife = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugTraceVCLife"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
            [FWDebugTimeProfiler enableTraceVCLife];
        } else {
            traceVCLife = NO;
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:@"FWDebugTraceVCLife"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        if (!cellSwitch.on) {
            traceVCRequest = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugTraceVCRequest"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
            [FWDebugTimeProfiler enableTraceVCRequest];
        } else {
            traceVCRequest = NO;
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugTraceVCRequest"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugWebViewNetworkEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
            [FWDebugAppConfig registerURLProtocolScheme:@"https"];
            [FWDebugAppConfig registerURLProtocolScheme:@"http"];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugWebViewNetworkEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
            [FWDebugAppConfig unregisterURLProtocolScheme:@"https"];
            [FWDebugAppConfig unregisterURLProtocolScheme:@"http"];
        }
    } else if (indexPath.section == 1 && indexPath.row == 1) {
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugWebViewInjectionEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
            [FWDebugAppConfig webViewInjectVConsole];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugWebViewInjectionEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    } else if (indexPath.section == 1 && indexPath.row == 2) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager showPrompt:self security:NO title:@"Input Javascript" message:nil text:[self.class webViewJavascriptString] block:^(BOOL confirm, NSString *text) {
            if (confirm) {
                if (text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugWebViewInjectionJavascript"];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugWebViewInjectionJavascript"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf configSwitch:cell indexPath:indexPath];
            [FWDebugAppConfig webViewInjectJavascript];
        }];
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        if (!cellSwitch.on) {
            filterSystemLog = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugFilterSystemLog"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        } else {
            filterSystemLog = NO;
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:@"FWDebugFilterSystemLog"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        if (!cellSwitch.on) {
            FLEXObjectExplorer.reflexAvailable = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugReflexEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        } else {
            FLEXObjectExplorer.reflexAvailable = NO;
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:@"FWDebugReflexEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self configSwitch:cell indexPath:indexPath];
        }
    } else if (indexPath.section == 2 && indexPath.row == 2) {
        if (!cellSwitch.on) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager showPrompt:self security:YES title:@"Input Password" message:nil text:nil block:^(BOOL confirm, NSString *text) {
                if (confirm && text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:[FWDebugAppConfig secretMd5:text] forKey:@"FWDebugAppSecret"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                [weakSelf configSwitch:cell indexPath:indexPath];
            }];
        } else {
            if ([self.class isSecretEnabled]) {
                typeof(self) __weak weakSelf = self;
                [FWDebugManager showPrompt:self security:YES title:@"Input Password" message:nil text:nil block:^(BOOL confirm, NSString *text) {
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
    } else if (indexPath.section == 2 && indexPath.row == 3) {
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
    if (indexPath.section == 0 && indexPath.row == 2) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[self.class traceVCUrls] block:^(BOOL confirm, NSString *text) {
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
    } else if (indexPath.section == 2 && indexPath.row == 4) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:nil block:^(BOOL confirm, NSString *text) {
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
    } else if (indexPath.section == 1 && indexPath.row == 3) {
        __weak UITableViewCell *weakCell = cell;
        [FWDebugManager showConfirm:self title:@"Are you sure you want to clear the cache of WKWebView?" message:nil block:^(BOOL confirm) {
            if (confirm) {
                weakCell.detailTextLabel.text = @"cleaning...";
                NSSet<NSString *> *dataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
                NSDate *sinceDate = [NSDate dateWithTimeIntervalSince1970:0];
                [WKWebsiteDataStore.defaultDataStore removeDataOfTypes:dataTypes modifiedSince:sinceDate completionHandler:^{
                    weakCell.detailTextLabel.text = @"";
                }];
            }
        }];
    }
}

@end
