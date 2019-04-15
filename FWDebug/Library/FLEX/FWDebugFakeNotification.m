//
//  FWDebugFakeNotification.m
//  FWDebug
//
//  Created by wuyong on 2019/4/13.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "FWDebugFakeNotification.h"
#import "FWDebugManager+FWDebug.h"
#import <UserNotifications/UserNotifications.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <unistd.h>
#import <ifaddrs.h>
#import "NWHub.h"
#import "NWLCore.h"
#import "NWNotification.h"
#import "NWPusher.h"
#import "NWSSLConnection.h"
#import "NWSecTools.h"
#import "NWPushFeedback.h"

@interface FWDebugFakeNotification () <NWHubDelegate>

@property (nonatomic, copy) NSString *pushCertPath;

@end

@implementation FWDebugFakeNotification {
    NWHub *_hub;
    NWIdentityRef _identity;
    NWCertificateRef _certificate;
}

#pragma mark - Static

+ (void)fwDebugLaunch
{
    if (![self isFakeEnabled]) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self startFakeServer];
    });
}

+ (BOOL)isFakeEnabled
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotification"] boolValue];
}

+ (NSInteger)fakeNotificatinPort
{
    NSInteger port = [[[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationPort"] integerValue];
    return port > 0 ? port : 9930;
}

+ (NSString *)fakeClientIP
{
    NSString *clientIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationClientIP"];
    return clientIP ? clientIP : [self getIPAddress];
}

+ (NSInteger)fakeClientPort
{
    NSInteger port = [[[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationClientPort"] integerValue];
    return port > 0 ? port : [self fakeNotificatinPort];
}

+ (NSString *)fakeClientMessage
{
    NSString *clientMessage = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationClientMessage"];
    if (clientMessage) {
        return clientMessage;
    } else {
        return @"{\"alert\":{\"title\":\"title\",\"body\":\"body\"},\"sound\":\"default\"}";
    }
}

+ (NSString *)fakeClientCommand
{
    return [NSString stringWithFormat:@"echo -n '%@' | nc -4u -w1 %@ %@", [self fakeClientMessage], [self fakeClientIP], @([self fakeClientPort])];
}

+ (void)startFakeServer
{
    static const NSInteger __buffer_length = 512;
    static struct sockaddr_in __si_me, __si_other;
    static int __socket;
    static int __port;
    static char __buffer[__buffer_length];
    static dispatch_source_t input_src;
    
    __port = (int)[self fakeNotificatinPort];
    if ((__socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) {
        NSLog(@"FWDebug: socket error");
    }
    
    memset((char *) &__si_me, 0, sizeof(__si_me));
    __si_me.sin_family = AF_INET;
    __si_me.sin_port = htons(__port);
    __si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    
    if (bind(__socket, (struct sockaddr*)&__si_me, sizeof(__si_me))==-1) {
        NSLog(@"FWDebug: bind error");
    }
    NSLog(@"FWDebug: listening on %@:%@", [self.class getIPAddress], @(__port));
    
    input_src = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, __socket, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(input_src,  ^{
        socklen_t slen = sizeof(__si_other);
        ssize_t size = 0;
        if ((size = recvfrom(__socket, __buffer, __buffer_length, 0, (struct sockaddr*)&__si_other, &slen))==-1) {
            NSLog(@"FWDebug: recvfrom error");
        }
        __buffer[size] = '\0';
        NSString *string = [NSString stringWithUTF8String:__buffer];
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (!dict) {
            NSLog(@"FWDebug: error = %@", error);
        } else if (![dict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"FWDebug: message error - %@", string);
        } else {
            BOOL success = NO;
            UIApplication *application = [UIApplication sharedApplication];
            if (@available(iOS 10.0, *)) {
                id<UNUserNotificationCenterDelegate> delegate = [UNUserNotificationCenter currentNotificationCenter].delegate;
                if (delegate) {
                    if (application.applicationState == UIApplicationStateActive) {
                        if (delegate && [delegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)]) {
                            [delegate userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter] willPresentNotification:nil withCompletionHandler:^(UNNotificationPresentationOptions options) {
                                
                            }];
                            success = YES;
                        }
                    } else {
                        if (delegate && [delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
                            [delegate userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter] didReceiveNotificationResponse:nil withCompletionHandler:^{
                                
                            }];
                            success = YES;
                        }
                    }
                }
            }
            if (!success) {
                if ([application.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
                    [application.delegate application:application didReceiveRemoteNotification:dict fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
                    success = YES;
                } else if ([application.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
                    [application.delegate application:application didReceiveRemoteNotification:dict];
                    success = YES;
                }
            }
            if (!success) {
                NSLog(@"FWDebug: message failed - %@", string);
            }
        }
    });
    dispatch_source_set_cancel_handler(input_src,  ^{
        NSLog(@"FWDebug: socket closed");
        close(__socket);
    });
    dispatch_resume(input_src);
}

+ (void)pushFakeMessage:(NSString *)payload
{
    static const NSInteger __buffer_length = 512;
    struct sockaddr_in si_other;
    int s;
    char buf[__buffer_length];
    static int __port;
    
    NSError *error = nil;
    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!dict || error) {
        NSLog(@"FWDebug: data error = %@", error);
        return;
    }
    
    __port = (int)[self fakeClientPort];
    if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1) {
        NSLog(@"FWDebug: socket error");
    }
    
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    si_other.sin_port = htons(__port);
    const char *host = [[self fakeClientIP] cStringUsingEncoding:NSUTF8StringEncoding];
    if (inet_aton(host, &si_other.sin_addr)==0) {
        NSLog(@"FWDebug: inet_aton error");
    }
    
    memset(buf, '\0', __buffer_length);
    strncpy(buf, [data bytes], MIN(data.length, __buffer_length));
    
    if (sendto(s, buf, strnlen(buf, __buffer_length), 0, (struct sockaddr*)&si_other, sizeof(si_other))==-1) {
        NSLog(@"FWDebug: sendto error");
    }
    
    close(s);
}

+ (NSString *)getIPAddress
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *result = nil;
    if (!getifaddrs(&interfaces)) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if (sa_type == AF_INET || sa_type == AF_INET6) {
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                if (!result || [result isEqualToString:@"0.0.0.0"] || ([result isEqualToString:@"127.0.0.1"] && ![addr isEqualToString:@"0.0.0.0"])) {
                    result = addr;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        freeifaddrs(interfaces);
    }
    return result ? result : @"0.0.0.0";
}

+ (NSString *)pushCertName
{
    NSString *certName = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationCertName"];
    return certName ? certName : @"pusher.p12";
}

+ (NSString *)pushCertPassword
{
    NSString *certPassword = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationCertPassword"];
    return certPassword ? certPassword : @"";
}

+ (BOOL)pushCertEnvironment
{
    NSNumber *certEnvironment = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationCertEnvironment"];
    return certEnvironment ? [certEnvironment boolValue] : NO;
}

+ (NSString *)pushDeviceToken
{
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationDeviceToken"];
    return deviceToken ? deviceToken : @"";
}

+ (NSString *)pushApnsMessage
{
    NSString *apnsMessage = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationApnsMessage"];
    if (apnsMessage) {
        return apnsMessage;
    } else {
        return @"{\"alert\":{\"title\":\"title\",\"body\":\"body\"},\"sound\":\"default\"}";
    }
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
    
    self.title = @"Fake Notification";
    
    // 创建推送pkcs12证书目录
    NSString *pushCertPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    pushCertPath = [[pushCertPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"PushCert"];
    _pushCertPath = pushCertPath;
    if (![[NSFileManager defaultManager] fileExistsAtPath:pushCertPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:pushCertPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return 5;
    } else {
        return 6;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Fake Server";
    } else if (section == 1) {
        return @"Fake Client";
    } else {
        return @"APNS Client";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger type = [self cellTypeAtIndexPath:indexPath];
    NSString *cellId = [NSString stringWithFormat:@"Cell%@", @(type)];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    
    if (type == 0) {
        UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
        accessoryView.userInteractionEnabled = NO;
        cell.accessoryView = accessoryView;
        
        [self configSwitch:cell indexPath:indexPath];
    } else if (type == 1) {
        UILabel *accessoryView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width / 2, 30)];
        accessoryView.font = [UIFont systemFontOfSize:14];
        accessoryView.textColor = [UIColor blackColor];
        accessoryView.textAlignment = NSTextAlignmentRight;
        cell.accessoryView = accessoryView;
        
        [self configLabel:cell indexPath:indexPath];
    } else if (type == 2) {
        cell.detailTextLabel.numberOfLines = 0;
        
        [self configLabel:cell indexPath:indexPath];
    } else if (type == 3) {
        UIButton *accessoryView = [UIButton buttonWithType:UIButtonTypeSystem];
        accessoryView.frame = CGRectMake(0, 0, 50, 30);
        accessoryView.titleLabel.font = [UIFont systemFontOfSize:14];
        accessoryView.titleLabel.textAlignment = NSTextAlignmentRight;
        [accessoryView addTarget:self action:@selector(actionButton:) forControlEvents:UIControlEventTouchUpInside];
        [accessoryView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        cell.accessoryView = accessoryView;
        
        [self configButton:cell indexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger type = [self cellTypeAtIndexPath:indexPath];
    if (type == 0) {
        [self actionSwitch:indexPath];
    } else {
        [self actionLabel:indexPath];
    }
}

- (NSInteger)cellTypeAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger type = 0;
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            type = 1;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0 || indexPath.row == 1) {
            type = 1;
        } else if (indexPath.row == 2 || indexPath.row == 3) {
            type = 2;
        } else if (indexPath.row == 4) {
            type = 3;
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 2) {
            type = 1;
        } else if (indexPath.row == 3 || indexPath.row == 4) {
            type = 2;
        } else if (indexPath.row == 5) {
            type = 3;
        }
    }
    return type;
}

- (void)configSwitch:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    if (indexPath.section == 0) {
        if ([self.class isFakeEnabled]) {
            cell.textLabel.text = @"Server Started";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = YES;
        } else {
            cell.textLabel.text = @"Server Stopped";
            cell.detailTextLabel.text = nil;
            cellSwitch.on = NO;
        }
    }
}

- (void)configLabel:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UILabel *cellLabel = (UILabel *)cell.accessoryView;
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Server Port";
            cellLabel.text = [NSString stringWithFormat:@"%@", @([self.class fakeNotificatinPort])];
            cell.detailTextLabel.text = [self.class getIPAddress];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Client IP";
            cellLabel.text = [self.class fakeClientIP];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Client Port";
            cellLabel.text = [NSString stringWithFormat:@"%@", @([self.class fakeClientPort])];
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Message";
            cell.detailTextLabel.text = [self.class fakeClientMessage];
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"Command";
            cell.detailTextLabel.text = [self.class fakeClientCommand];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Cert Name";
            cell.detailTextLabel.text = @"FWDebug/PushCert/";
            cellLabel.text = [self.class pushCertName];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Cert Password";
            cellLabel.text = [self.class pushCertPassword];
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Cert Environment";
            cellLabel.text = [self.class pushCertEnvironment] ? @"Production" : @"Sandbox";
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"Device Token";
            cell.detailTextLabel.text = [self.class pushDeviceToken];
        } else if (indexPath.row == 4) {
            cell.textLabel.text = @"Message";
            cell.detailTextLabel.text = [self.class pushApnsMessage];
        }
    }
}

- (void)configButton:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UIButton *cellButton = (UIButton *)cell.accessoryView;
    if (indexPath.section == 1) {
        if (indexPath.row == 4) {
            cell.textLabel.text = @"";
            cellButton.tag = 1;
            [cellButton setTitle:@"Push" forState:UIControlStateNormal];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 5) {
            cell.textLabel.text = @"";
            cellButton.tag = 2;
            [cellButton setTitle:@"Push" forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Action

- (void)actionSwitch:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    
    if (indexPath.section == 0) {
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugFakeNotification"];
            [self.class fwDebugLaunch];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotification"];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self configSwitch:cell indexPath:indexPath];
    }
}

- (void)actionLabel:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[NSString stringWithFormat:@"%@", @([self.class fakeNotificatinPort])] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    NSInteger value = [text integerValue];
                    if (value > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:@"FWDebugFakeNotificationPort"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationPort"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[self.class fakeClientIP] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    if (text.length > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeNotificationClientIP"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationClientIP"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        } else if (indexPath.row == 1) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[NSString stringWithFormat:@"%@", @([self.class fakeClientPort])] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    NSInteger value = [text integerValue];
                    if (value > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:@"FWDebugFakeNotificationClientPort"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationClientPort"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        } else if (indexPath.row == 2) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[self.class fakeClientMessage] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    if (text.length > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeNotificationClientMessage"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationClientMessage"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        } else if (indexPath.row == 3) {
            [[UIPasteboard generalPasteboard] setString:[self.class fakeClientCommand]];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[self.class pushCertName] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    if (text.length > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeNotificationCertName"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationCertName"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        } else if (indexPath.row == 1) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[self.class pushCertPassword] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    if (text.length > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeNotificationCertPassword"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationCertPassword"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        } else if (indexPath.row == 2) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:([self.class pushCertEnvironment] ? @"1" : @"0") block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    if ([text boolValue]) {
                        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugFakeNotificationCertEnvironment"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationCertEnvironment"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        } else if (indexPath.row == 3) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[self.class pushDeviceToken] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    if (text.length > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeNotificationDeviceToken"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationDeviceToken"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        } else if (indexPath.row == 4) {
            typeof(self) __weak weakSelf = self;
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:[self.class pushApnsMessage] block:^(BOOL confirm, NSString *text) {
                if (confirm) {
                    if (text.length > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeNotificationApnsMessage"];
                    } else {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationApnsMessage"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        }
    }
}

- (void)actionButton:(UIButton *)button {
    if (button.tag == 1) {
        NSString *payload = [self.class fakeClientMessage];
        [self.class pushFakeMessage:payload];
    } else if (button.tag == 2) {
        NSString *pkcs12File = [self.pushCertPath stringByAppendingPathComponent:[self.class pushCertName]];
        NSData *pkcs12Data = [NSData dataWithContentsOfFile:pkcs12File];
        if (!pkcs12Data) {
            NSLog(@"FWDebug: %@ does not exist", [self.class pushCertName]);
            return;
        }
        
        NSError *error = nil;
        NSArray *ids = [NWSecTools identitiesWithPKCS12Data:pkcs12Data password:[self.class pushCertPassword] error:&error];
        if (!ids) {
            NSLog(@"FWDebug: Unable to read p12 file: %@", error.localizedDescription);
            return;
        }
        
        for (NWIdentityRef identity in ids) {
            NWCertificateRef certificate = [NWSecTools certificateWithIdentity:identity error:&error];
            if (!certificate) {
                NSLog(@"FWDebug: Unable to import p12 file: %@", error.localizedDescription);
                return;
            }
            
            _identity = identity;
            _certificate = certificate;
        }
        
        if (_hub) {
            [_hub disconnect];
            _hub = nil;
        }
        
        NWEnvironment environment = [self.class pushCertEnvironment] ? NWEnvironmentProduction : NWEnvironmentSandbox;
        NWHub *hub = [NWHub connectWithDelegate:self identity:_identity environment:environment error:&error];
        if (hub) {
            NSString *summary = [NWSecTools summaryWithCertificate:_certificate];
            NSLog(@"FWDebug: Connected to APN: %@ (%@)", summary, ([self.class pushCertEnvironment] ? @"Production" : @"Sandbox"));
            _hub = hub;
            
            NSLog(@"FWDebug: Pushing..");
            NSUInteger failed = [_hub pushPayload:[self.class pushApnsMessage] token:[self.class pushDeviceToken]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSUInteger failed2 = failed + [_hub readFailed];
                if (!failed2) NSLog(@"FWDebug: Payload has been pushed");
            });
        } else {
            NSLog(@"FWDebug: Unable to connect: %@", error.localizedDescription);
        }
        
        /*
        NWPusher *pusher = [NWPusher connectWithPKCS12Data:pkcs12Data password:[self.class pushCertPassword] environment:([self.class pushCertEnvironment] ? NWEnvironmentProduction : NWEnvironmentSandbox) error:&error];
        if (!pusher || error) {
            NSLog(@"FWDebug: Unable to connect: %@", error);
            return;
        }
        
        BOOL pushed = [pusher pushPayload:[self.class pushApnsMessage] token:[self.class pushDeviceToken] identifier:rand() error:&error];
        if (!pushed || error) {
            NSLog(@"FWDebug: Unable to push: %@", error);
            return;
        }
            
        NSUInteger identifier = 0;
        NSError *apnError = nil;
        BOOL read = [pusher readFailedIdentifier:&identifier apnError:&apnError error:&error];
        if (read && apnError) {
            NSLog(@"FWDebug: Notification with identifier %i rejected: %@", (int)identifier, apnError);
        } else if (read) {
            NSLog(@"FWDebug: Read and none failed");
        } else {
            NSLog(@"FWDebug: Unable to read: %@", error);
        }*/
    }
}

@end
