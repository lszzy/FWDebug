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
#import "NWPusher.h"

@interface UNNotification ()

+ (instancetype)notificationWithRequest:(UNNotificationRequest *)request date:(NSDate *)date;

@end

@interface UNNotificationResponse ()

+ (instancetype)responseWithNotification:(UNNotification *)notification actionIdentifer:(NSString *)actionIdentifier;

@end

static const NSInteger FWDebugBufferLength = 512;

@interface FWDebugFakeNotification ()

@property (nonatomic, copy) NSString *pushCertPath;

@end

@implementation FWDebugFakeNotification

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
    return clientIP ? clientIP : [self fakeIPAddress];
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
        return @"{\"aps\":{\"alert\":{\"title\":\"title\",\"body\":\"body\"},\"badge\":1,\"sound\":\"default\"}}";
    }
}

+ (NSString *)fakeClientCommand
{
    return [NSString stringWithFormat:@"echo -n '%@' | nc -4u -w1 %@ %@", [self fakeClientMessage], [self fakeClientIP], @([self fakeClientPort])];
}

+ (void)startFakeServer
{
    static struct sockaddr_in si_server, si_client;
    static int server_socket, server_port;
    static char server_buffer[FWDebugBufferLength];
    static dispatch_source_t input_src;
    
    server_port = (int)[self fakeNotificatinPort];
    if ((server_socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) {
        NSLog(@"FWDebug: socket error");
    }
    
    memset((char *)&si_server, 0, sizeof(si_server));
    si_server.sin_family = AF_INET;
    si_server.sin_port = htons(server_port);
    si_server.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(server_socket, (struct sockaddr *)&si_server, sizeof(si_server)) == -1) {
        NSLog(@"FWDebug: socket bind error");
    } else {
        NSLog(@"FWDebug: socket bind on %@:%@", [self.class fakeIPAddress], @(server_port));
    }
    
    input_src = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, server_socket, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(input_src,  ^{
        socklen_t slen = sizeof(si_client);
        ssize_t size = 0;
        if ((size = recvfrom(server_socket, server_buffer, FWDebugBufferLength, 0, (struct sockaddr*)&si_client, &slen)) == -1) {
            NSLog(@"FWDebug: socket recvfrom error");
        }
        server_buffer[size] = '\0';
        NSString *string = [NSString stringWithUTF8String:server_buffer];
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"FWDebug: socket decode error - %@", string);
        } else {
            if ([self isFakeEnabled]) {
                [self handleFakeNotification:dict];
            }
        }
    });
    dispatch_source_set_cancel_handler(input_src,  ^{
        close(server_socket);
        NSLog(@"FWDebug: socket closed");
    });
    dispatch_resume(input_src);
}

+ (void)pushFakeMessage:(NSString *)payload
{
    struct sockaddr_in si_client;
    int client_socket;
    static int client_port;
    char client_buffer[FWDebugBufferLength];
    
    NSError *error = nil;
    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        NSLog(@"FWDebug: client data error - %@", payload);
        return;
    }
    
    client_port = (int)[self fakeClientPort];
    if ((client_socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) {
        NSLog(@"FWDebug: client socket error");
    }
    
    memset((char *)&si_client, 0, sizeof(si_client));
    si_client.sin_family = AF_INET;
    si_client.sin_port = htons(client_port);
    const char *host = [[self fakeClientIP] cStringUsingEncoding:NSUTF8StringEncoding];
    if (inet_aton(host, &si_client.sin_addr) == 0) {
        NSLog(@"FWDebug: client inet_aton error");
    }
    
    memset(client_buffer, '\0', FWDebugBufferLength);
    strncpy(client_buffer, [data bytes], MIN(data.length, FWDebugBufferLength));
    if (sendto(client_socket, client_buffer, strnlen(client_buffer, FWDebugBufferLength), 0, (struct sockaddr *)&si_client, sizeof(si_client)) == -1) {
        NSLog(@"FWDebug: client sendto error");
    }
    close(client_socket);
}

+ (UNNotification *)notificationWithUserInfo:(NSDictionary *)userInfo
{
    // content
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.userInfo = userInfo;
    NSDictionary *apsDict = [userInfo[@"aps"] isKindOfClass:[NSDictionary class]] ? userInfo[@"aps"] : nil;
    id badgeValue = apsDict[@"badge"];
    if (badgeValue) {
        if ([badgeValue isKindOfClass:[NSNumber class]]) {
            content.badge = badgeValue;
        } else if ([badgeValue isKindOfClass:[NSString class]]) {
            content.badge = [NSNumber numberWithInteger:[badgeValue integerValue]];
        }
    }
    NSString *soundName = [apsDict[@"sound"] isKindOfClass:[NSString class]] ? apsDict[@"sound"] : nil;
    if (soundName.length > 0) {
        content.sound = [soundName isEqualToString:@"default"] ? [UNNotificationSound defaultSound] : [UNNotificationSound soundNamed:soundName];
    }
    content.threadIdentifier = [apsDict[@"thread-id"] isKindOfClass:[NSString class]] ? apsDict[@"thread-id"] : nil;
    content.categoryIdentifier = [apsDict[@"category"] isKindOfClass:[NSString class]] ? apsDict[@"category"] : nil;
    NSDictionary *alertDict = [apsDict[@"alert"] isKindOfClass:[NSDictionary class]] ? apsDict[@"alert"] : nil;
    if ([alertDict[@"title"] isKindOfClass:[NSString class]]) {
        content.title = alertDict[@"title"];
    } else if ([apsDict[@"title"] isKindOfClass:[NSString class]]) {
        content.title = apsDict[@"title"];
    }
    content.subtitle = [alertDict[@"subtitle"] isKindOfClass:[NSString class]] ? alertDict[@"subtitle"] : nil;
    content.body = [alertDict[@"body"] isKindOfClass:[NSString class]] ? alertDict[@"body"] : nil;
    content.launchImageName = [alertDict[@"launch-image"] isKindOfClass:[NSString class]] ? alertDict[@"launch-image"] : nil;
    
    // request
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString *identifier = (__bridge_transfer NSString *)string;
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:[content copy] trigger:[UNPushNotificationTrigger new]];
    
    // notification
    UNNotification *notification = nil;
    if ([UNNotification respondsToSelector:@selector(notificationWithRequest:date:)]) {
        notification = [UNNotification notificationWithRequest:request date:[NSDate date]];
    }
    return notification;
}

+ (void)handleFakeNotification:(NSDictionary *)userInfo
{
    BOOL handled = NO;
    UIApplication *application = [UIApplication sharedApplication];
    if (@available(iOS 10.0, *)) {
        id<UNUserNotificationCenterDelegate> delegate = [UNUserNotificationCenter currentNotificationCenter].delegate;
        if (delegate) {
            if (application.applicationState == UIApplicationStateActive) {
                if (delegate && [delegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)]) {
                    UNNotification *notification = [self notificationWithUserInfo:userInfo];
                    [delegate userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter] willPresentNotification:notification withCompletionHandler:^(UNNotificationPresentationOptions options) {
                        if ((options & UNNotificationPresentationOptionAlert) == UNNotificationPresentationOptionAlert) {
                            if (delegate && [delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
                                UNNotificationResponse *response = nil;
                                if ([UNNotificationResponse respondsToSelector:@selector(responseWithNotification:actionIdentifer:)]) {
                                    response = [UNNotificationResponse responseWithNotification:notification actionIdentifer:UNNotificationDefaultActionIdentifier];
                                }
                                [delegate userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter] didReceiveNotificationResponse:response withCompletionHandler:^{}];
                            }
                        }
                    }];
                    handled = YES;
                }
            } else {
                if (delegate && [delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
                    UNNotification *notification = [self notificationWithUserInfo:userInfo];
                    UNNotificationResponse *response = nil;
                    if ([UNNotificationResponse respondsToSelector:@selector(responseWithNotification:actionIdentifer:)]) {
                        response = [UNNotificationResponse responseWithNotification:notification actionIdentifer:UNNotificationDefaultActionIdentifier];
                    }
                    [delegate userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter] didReceiveNotificationResponse:response withCompletionHandler:^{}];
                    handled = YES;
                }
            }
        }
    }
    if (!handled) {
        if ([application.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
            [application.delegate application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
            handled = YES;
        } else if ([application.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
            [application.delegate application:application didReceiveRemoteNotification:userInfo];
            handled = YES;
        }
    }
    if (!handled) {
        NSLog(@"FWDebug: socket handle failed - %@", userInfo);
    }
}

+ (NSString *)fakeIPAddress
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
    if (deviceToken) {
        return deviceToken;
    } else {
        // 兼容FWFramework
        deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
        return deviceToken ? deviceToken : @"";
    }
}

+ (NSString *)pushApnsMessage
{
    NSString *apnsMessage = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeNotificationApnsMessage"];
    if (apnsMessage) {
        return apnsMessage;
    } else {
        return @"{\"aps\":{\"alert\":{\"title\":\"title\",\"body\":\"body\"},\"badge\":1,\"sound\":\"default\"}}";
    }
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [super initWithStyle:UITableViewStyleGrouped];
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

#pragma mark - TableView

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
            cell.detailTextLabel.text = [self.class fakeIPAddress];
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
    typeof(self) __weak weakSelf = self;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
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
        [self.class pushFakeMessage:[self.class fakeClientMessage]];
    } else if (button.tag == 2) {
        NSString *pkcs12File = [self.pushCertPath stringByAppendingPathComponent:[self.class pushCertName]];
        NSData *pkcs12Data = [NSData dataWithContentsOfFile:pkcs12File];
        if (!pkcs12Data) {
            NSLog(@"FWDebug: %@ does not exist", [self.class pushCertName]);
            return;
        }
        
        NSError *error = nil;
        NWPusher *pusher = [NWPusher connectWithPKCS12Data:pkcs12Data password:[self.class pushCertPassword] environment:([self.class pushCertEnvironment] ? NWEnvironmentProduction : NWEnvironmentSandbox) error:&error];
        if (!pusher || error) {
            NSLog(@"FWDebug: unable to connect - %@", error);
            return;
        }
        
        NSUInteger identifier = 0;
        BOOL pushed = [pusher pushPayload:[self.class pushApnsMessage] token:[self.class pushDeviceToken] identifier:identifier error:&error];
        if (!pushed || error) {
            NSLog(@"FWDebug: unable to push: %@", error);
            return;
        }
        
        NSError *apnError = nil;
        BOOL readed = [pusher readFailedIdentifier:&identifier apnError:&apnError error:&error];
        if (readed && apnError) {
            NSLog(@"FWDebug: push rejected %i - %@", (int)identifier, apnError);
        } else if (readed) {
            NSLog(@"FWDebug: push success");
        } else {
            NSLog(@"FWDebug: unable to read - %@", error);
        }
    }
}

@end
