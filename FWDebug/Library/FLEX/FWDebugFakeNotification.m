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

@interface FWDebugFakeNotification ()

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
        [self listenForRemoteNotifications];
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

+ (void)listenForRemoteNotifications
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
            NSLog(@"FWDebug: message error");
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
                } else {
                    if ([application.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
                        [application.delegate application:application didReceiveRemoteNotification:dict];
                    }
                }
            }
        }
    });
    dispatch_source_set_cancel_handler(input_src,  ^{
        NSLog(@"FWDebug: socket closed");
        close(__socket);
    });
    dispatch_resume(input_src);
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Fake Server";
    } else {
        return @"Fake Client";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FakeNotificationCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FakeNotificationCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    
    NSInteger type = [self cellTypeAtIndexPath:indexPath];
    if (type == 0) {
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
    
    NSInteger type = [self cellTypeAtIndexPath:indexPath];
    if (type == 0) {
        [self actionSwitch:indexPath];
    } else {
        [self actionLabel:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    BOOL canPerformAction = NO;
    if (action == @selector(copy:)) {
        canPerformAction = YES;
    }
    return canPerformAction;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        NSString *stringToCopy = @"";
        
        [[UIPasteboard generalPasteboard] setString:stringToCopy];
    }
}

- (NSInteger)cellTypeAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger type = 0;
    if (indexPath.section == 0 && indexPath.row == 1) {
        type = 1;
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
    }
}

#pragma mark - Action

- (void)actionSwitch:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    
    if (indexPath.section == 0) {
        if (!cellSwitch.on) {
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugFakeNotification"];
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
            [FWDebugManager fwDebugShowPrompt:self security:NO title:@"Input Value" message:nil text:nil block:^(BOOL confirm, NSString *text) {
                if (confirm && text.length > 0) {
                    NSInteger value = [text integerValue];
                    if (indexPath.row == 1) {
                        if (value > 0) {
                            [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:@"FWDebugFakeNotificationPort"];
                        } else {
                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeNotificationPort"];
                        }
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [weakSelf configLabel:cell indexPath:indexPath];
            }];
        }
    }
}

@end
