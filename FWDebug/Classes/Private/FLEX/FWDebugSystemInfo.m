//
//  FWDebugDeviceInfo.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugSystemInfo.h"
#import "FWDebugManager+FWDebug.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#include <Endian.h>

#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#import <mach/mach.h>
#import <mach/mach_host.h>
#include <mach/machine.h>

#include <net/if.h>
#include <net/if_dl.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#define FWDebugStr(str) (str ? [NSString stringWithFormat:@"%@", str] : @"-")
#define FWDebugBool(expr) ((expr) ? @"Yes" : @"No")
#define FWDebugDesc(expr) ((expr != nil) ? [expr description] : @"-")

@interface FWDebugSystemInfo ()

@property (nonatomic, strong) NSMutableArray *systemInfo;
@property (nonatomic, strong) NSMutableArray *tableData;

@end

@implementation FWDebugSystemInfo

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Device Info";
    self.showsSearchBar = YES;
    
    [self initSystemInfo];
    self.tableData = self.systemInfo;
}

- (void)initSystemInfo
{
    self.systemInfo = [NSMutableArray array];
    NSMutableArray *rowsData = [NSMutableArray array];
    NSDictionary *sectionData = nil;
    
    //Application
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *applicationName = [infoDictionary objectForKey:(__bridge NSString *)kCFBundleExecutableKey];
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    [rowsData addObjectsFromArray:@[
                                    @{ @"Name" : FWDebugStr(applicationName) },
                                    @{ @"Version" : FWDebugStr(version) },
                                    @{ @"Build" : FWDebugStr(build) },
                                    @{ @"Build Date" : [NSString stringWithFormat:@"%@ - %@", [NSString stringWithUTF8String:__DATE__], [NSString stringWithUTF8String:__TIME__]] },
                                    @{ @"Bundle ID" : [[NSBundle mainBundle] bundleIdentifier] },
                                    @{ @"Debug" : FWDebugBool([self isDebug]) },
                                    @{ @"Badge Number" : [@([UIApplication sharedApplication].applicationIconBadgeNumber) stringValue] },
                                    ]];
    NSArray *urlSchemes = [self urlSchemes];
    if (urlSchemes.count > 1) {
        for (int i = 0; i < urlSchemes.count; i++) {
            [rowsData addObject:@{ @"Url Schemes" : FWDebugStr([urlSchemes objectAtIndex:i]) }];
        }
    } else {
        [rowsData addObject:@{ @"Url Scheme" : FWDebugStr(urlSchemes.count > 0 ? [urlSchemes objectAtIndex:0] : nil) }];
    }
    
    sectionData = @{
                    @"title": @"Application",
                    @"rows": rowsData.copy,
                    };
    [rowsData removeAllObjects];
    [self.systemInfo addObject:sectionData];
    
    //Usage
    sectionData = @{
                    @"title": @"Usage",
                    @"rows": @[
                            @{ @"Memory Size" : [NSByteCountFormatter stringFromByteCount:[self memorySize] countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Documents Size" : [self sizeOfFolder:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]] },
                            @{ @"Sandbox Size" : [self sizeOfFolder:NSHomeDirectory()] },
                            ]
                    };
    [self.systemInfo addObject:sectionData];
    
    //System
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    BOOL lowPowerMode = NO;
    if (@available(iOS 9.0, *)) {
        lowPowerMode = [[NSProcessInfo processInfo] isLowPowerModeEnabled];
    }
    sectionData = @{
                    @"title": @"System",
                    @"rows": @[
                            @{ @"System Version" : [NSString stringWithFormat:@"%@ %@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion] },
                            @{ @"System Time" : [dateFormatter stringFromDate:[NSDate date]] },
                            @{ @"Boot Time" : [dateFormatter stringFromDate:[self systemBootDate]] },
                            @{ @"Low Power Mode" : FWDebugBool(lowPowerMode) }
                            ]
                    };
    [self.systemInfo addObject:sectionData];
    
    //Locale
    NSArray *languages = [NSLocale preferredLanguages];
    for (NSString *language in languages) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
        NSString *title = languages.count > 1 ? @"User Languages" : @"User Language";
        [rowsData addObject:@{ title : [locale displayNameForKey:NSLocaleIdentifier value:language] }];
    }
    NSString *region = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
    [rowsData addObjectsFromArray:@[
                                    @{ @"Timezone" : [NSTimeZone localTimeZone].name },
                                    @{ @"Region" : [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:region] },
                                    @{ @"Calendar" : [[[[NSLocale currentLocale] objectForKey:NSLocaleCalendar] calendarIdentifier] capitalizedString] }
                                    ]];
    
    sectionData = @{
                    @"title": @"Locale",
                    @"rows": rowsData.copy
                    };
    [rowsData removeAllObjects];
    [self.systemInfo addObject:sectionData];
    
    //Device
    sectionData = @{
                    @"title": @"Device",
                    @"rows": @[
                            @{ @"Name" : [UIDevice currentDevice].name },
                            @{ @"Identifier" : self.modelIdentifier },
                            @{ @"CPU Count" : [NSString stringWithFormat:@"%lu", (unsigned long)(self.cpuPhysicalCount)] },
                            @{ @"CPU Type" : self.cpuType },
                            @{ @"Architectures" : self.cpuArchitectures },
                            @{ @"Total Memory" : [NSByteCountFormatter stringFromByteCount:self.memoryMarketingSize countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Available Memory" : [NSByteCountFormatter stringFromByteCount:self.memoryPhysicalSize countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Capacity" : [NSByteCountFormatter stringFromByteCount:self.diskMarketingSpace countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Total Capacity" : [NSByteCountFormatter stringFromByteCount:self.diskTotalSpace countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Free Capacity" : [NSByteCountFormatter stringFromByteCount:self.diskFreeSpace countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Battery level" : [NSString stringWithFormat:@"%ld%%", (long)([UIDevice currentDevice].batteryLevel * 100)] },
                            @{ @"UUID" : FWDebugStr(self.identifierUUID) },
                            @{ @"Jailbroken" : FWDebugBool(self.isJailbreak) },
                            ]
                    };
    [self.systemInfo addObject:sectionData];
    
    //Local IP Addresses
    NSDictionary* ipInfo = self.localIPAddresses;
    for (NSString* key in ipInfo) {
        [rowsData addObject:@{ [NSString stringWithFormat:@"IP (%@)", key] : ipInfo[key] }];
    }
    
    sectionData = @{
                    @"title": @"Local IP Addresses",
                    @"rows": rowsData.copy
                    };
    [rowsData removeAllObjects];
    [self.systemInfo addObject:sectionData];
    
    //Network
    sectionData = @{
                    @"title": @"Network",
                    @"rows": @[
                            @{ @"MAC Address" : FWDebugDesc(self.macAddress) },
                            @{ @"SSID" : FWDebugDesc(self.SSID) },
                            @{ @"BSSDID" : FWDebugDesc(self.BSSID) },
                            @{ @"Received Wi-Fi" : [NSByteCountFormatter stringFromByteCount:self.receivedWiFi.longLongValue countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Sent Wi-Fi" : [NSByteCountFormatter stringFromByteCount:self.sentWifi.longLongValue countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Received Cellular" : [NSByteCountFormatter stringFromByteCount:self.receivedCellular.longLongValue countStyle:NSByteCountFormatterCountStyleBinary] },
                            @{ @"Sent Cellular" : [NSByteCountFormatter stringFromByteCount:self.sentCellular.longLongValue countStyle:NSByteCountFormatterCountStyleBinary] }
                            ]
                    };
    [self.systemInfo addObject:sectionData];
    
    //Cellular
    CTTelephonyNetworkInfo* info = [[CTTelephonyNetworkInfo alloc] init];
    
    sectionData = @{
                    @"title": @"Cellular",
                    @"rows": @[
                            @{ @"Carrier Name" : FWDebugDesc([info.subscriberCellularProvider.carrierName capitalizedString]) },
                            @{ @"Data Connection": FWDebugDesc([info.currentRadioAccessTechnology stringByReplacingOccurrencesOfString:@"CTRadioAccessTechnology" withString:@""]) },
                            @{ @"Country Code" : FWDebugDesc(info.subscriberCellularProvider.mobileCountryCode) },
                            @{ @"Network Code" : FWDebugDesc(info.subscriberCellularProvider.mobileNetworkCode) },
                            @{ @"ISO Country Code" : FWDebugDesc(info.subscriberCellularProvider.isoCountryCode) },
                            @{ @"VoIP Enabled" : FWDebugBool(info.subscriberCellularProvider.allowsVOIP) }
                            ]
                    };
    [self.systemInfo addObject:sectionData];
}

- (void)reloadSystemInfo
{
    [self initSystemInfo];
    self.tableData = self.systemInfo;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self.tableData objectAtIndex:section] objectForKey:@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = [[self.tableData objectAtIndex:section] objectForKey:@"rows"];
    return sectionData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SystemInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    }
    
    NSArray *sectionData = [[self.tableData objectAtIndex:indexPath.section] objectForKey:@"rows"];
    NSDictionary *cellData = [sectionData objectAtIndex:indexPath.row];
    
    for (NSString *key in cellData) {
        cell.textLabel.text = key;
        cell.detailTextLabel.text = [cellData objectForKey:key];
        break;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    BOOL canPerformAction = NO;
    
    if (action == @selector(copy:)) {
        canPerformAction = YES;
    }
    
    return canPerformAction;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        NSString *stringToCopy = @"";
        
        NSArray *sectionData = [[self.tableData objectAtIndex:indexPath.section] objectForKey:@"rows"];
        NSDictionary *cellData = [sectionData objectAtIndex:indexPath.row];
        for (NSString *key in cellData) {
            stringToCopy = [stringToCopy stringByAppendingString:[cellData objectForKey:key]];
            break;
        }
        
        [[UIPasteboard generalPasteboard] setString:stringToCopy];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager showPrompt:self security:NO title:@"Fake Name" message:nil text:[self.class fakeBundleExecutable] block:^(BOOL confirm, NSString *text) {
            if (confirm) {
                if (text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugBundleExecutable"];
                    [FWDebugSystemInfo fakeBundleInfoDictionary];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugBundleExecutable"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf reloadSystemInfo];
        }];
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager showPrompt:self security:NO title:@"Fake Version" message:nil text:[self.class fakeBundleShortVersion] block:^(BOOL confirm, NSString *text) {
            if (confirm) {
                if (text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugBundleShortVersion"];
                    [FWDebugSystemInfo fakeBundleInfoDictionary];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugBundleShortVersion"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf reloadSystemInfo];
        }];
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager showPrompt:self security:NO title:@"Fake Build" message:nil text:[self.class fakeBundleBuildVersion] block:^(BOOL confirm, NSString *text) {
            if (confirm) {
                if (text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugBundleBuildVersion"];
                    [FWDebugSystemInfo fakeBundleInfoDictionary];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugBundleBuildVersion"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf reloadSystemInfo];
        }];
    } else if (indexPath.section == 0 && indexPath.row == 4) {
        typeof(self) __weak weakSelf = self;
        [FWDebugManager showPrompt:self security:NO title:@"Fake Bundle ID" message:nil text:[self.class fakeBundleIdentifier] block:^(BOOL confirm, NSString *text) {
            if (confirm) {
                if (text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugBundleIdentifier"];
                    [FWDebugSystemInfo fakeBundleInfoDictionary];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugBundleIdentifier"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf reloadSystemInfo];
        }];
    }
}

#pragma mark - Fake Bundle

+ (void)fwDebugLaunch
{
    if ([self fakeBundleExecutable].length > 0 ||
        [self fakeBundleShortVersion].length > 0 ||
        [self fakeBundleBuildVersion].length > 0 ||
        [self fakeBundleIdentifier].length > 0) {
        [self fakeBundleInfoDictionary];
    }
}

+ (NSString *)fakeBundleExecutable
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:@"FWDebugBundleExecutable"];
    return value ?: @"";
}

+ (NSString *)fakeBundleShortVersion
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:@"FWDebugBundleShortVersion"];
    return value ?: @"";
}

+ (NSString *)fakeBundleBuildVersion
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:@"FWDebugBundleBuildVersion"];
    return value ?: @"";
}

+ (NSString *)fakeBundleIdentifier
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:@"FWDebugBundleIdentifier"];
    return value ?: @"";
}

+ (void)fakeBundleInfoDictionary
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager swizzleMethod:@selector(infoDictionary) in:[NSBundle class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(__unsafe_unretained NSBundle *selfObject) {
                NSDictionary *infoDictionary = ((NSDictionary * (*)(id, SEL))originalIMP())(selfObject, originalCMD);
                if ([FWDebugSystemInfo fakeBundleExecutable].length <= 0 &&
                    [FWDebugSystemInfo fakeBundleShortVersion].length <= 0 &&
                    [FWDebugSystemInfo fakeBundleBuildVersion].length <= 0 &&
                    [FWDebugSystemInfo fakeBundleIdentifier].length <= 0) {
                    return infoDictionary;
                }
                
                NSMutableDictionary *mutableInfo = [infoDictionary mutableCopy];
                if ([FWDebugSystemInfo fakeBundleExecutable].length > 0) {
                    mutableInfo[(__bridge NSString *)kCFBundleExecutableKey] = [FWDebugSystemInfo fakeBundleExecutable];
                }
                if ([FWDebugSystemInfo fakeBundleShortVersion].length > 0) {
                    mutableInfo[@"CFBundleShortVersionString"] = [FWDebugSystemInfo fakeBundleShortVersion];
                }
                if ([FWDebugSystemInfo fakeBundleBuildVersion].length > 0) {
                    mutableInfo[(__bridge NSString *)kCFBundleVersionKey] = [FWDebugSystemInfo fakeBundleBuildVersion];
                }
                if ([FWDebugSystemInfo fakeBundleIdentifier].length > 0) {
                    mutableInfo[(__bridge NSString *)kCFBundleIdentifierKey] = [FWDebugSystemInfo fakeBundleIdentifier];
                }
                infoDictionary = [mutableInfo copy];
                return infoDictionary;
            };
        }];
    });
}

#pragma mark - Search bar

- (void)updateSearchResults:(NSString *)searchText
{
    if (searchText.length > 0) {
        NSMutableArray *sectionRows = [NSMutableArray array];
        for (NSDictionary *sectionData in self.systemInfo) {
            NSArray *cellDatas = [sectionData objectForKey:@"rows"];
            for (NSDictionary *cellData in cellDatas) {
                for (NSString *cellKey in cellData) {
                    if ([cellKey rangeOfString:searchText].location != NSNotFound ||
                        [[cellData objectForKey:cellKey] rangeOfString:searchText].location != NSNotFound) {
                        [sectionRows addObject:cellData];
                    }
                    break;
                }
            }
        }
        
        self.tableData = [NSMutableArray array];
        NSDictionary *sectionData = @{
                                      @"title": [NSString stringWithFormat:@"%@ Results", @(sectionRows.count)],
                                      @"rows": sectionRows,
                                      };
        [self.tableData addObject:sectionData];
        [self.tableView reloadData];
    } else {
        self.tableData = self.systemInfo;
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (NSString *)sizeOfFolder:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    return folderSizeStr;
}

- (long long)memorySize
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    if (kerr == KERN_SUCCESS) {
        return (long long)info.resident_size;
    } else {
        return -1;
    }
}

- (NSDate *)systemBootDate
{
    const int MIB_SIZE = 2;
    
    int mib[MIB_SIZE];
    size_t size;
    struct timeval  boottime;
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_BOOTTIME;
    size = sizeof(boottime);
    
    if (sysctl(mib, MIB_SIZE, &boottime, &size, NULL, 0) != -1) {
        NSDate* bootDate = [NSDate dateWithTimeIntervalSince1970:boottime.tv_sec + boottime.tv_usec / 1.e6];
        return bootDate;
    }
    
    return nil;
}

#pragma mark - CPU related

- (NSUInteger)cpuCount
{
    return (NSUInteger)[[self systemInfoByName:@"hw.ncpu"] integerValue];
}

- (NSUInteger)cpuActiveCount
{
    return (NSUInteger)[[self systemInfoByName:@"hw.activecpu"] integerValue];
}

- (NSUInteger)cpuPhysicalCount
{
    return (NSUInteger)[[self systemInfoByName:@"hw.physicalcpu"] integerValue];
}

- (NSUInteger)cpuPhysicalMaximumCount
{
    return (NSUInteger)[[self systemInfoByName:@"hw.physicalcpu_max"] integerValue];
}

- (NSUInteger)cpuLogicalCount
{
    return (NSUInteger)[[self systemInfoByName:@"hw.logicalcpu"] integerValue];
}

- (NSUInteger)cpuLogicalMaximumCount
{
    return (NSUInteger)[[self systemInfoByName:@"hw.logicalcpu_max"] integerValue];
}

- (NSUInteger)cpuFrequency
{
    return (NSUInteger)[[self systemInfoByName:@"hw.cpufrequency"] integerValue];
}

- (NSUInteger)cpuMaximumFrequency
{
    return (NSUInteger)[[self systemInfoByName:@"hw.cpufrequency_max"] integerValue];
}

- (NSUInteger)cpuMinimumFrequency
{
    return (NSUInteger)[[self systemInfoByName:@"hw.cpufrequency_min"] integerValue];
}

- (NSString *)cpuType
{
    NSString *cpuType = [self systemInfoByName:@"hw.cputype"];
    
    switch (cpuType.integerValue) {
        case 1:
            return @"VAC";
        case 6:
            return @"MC680x0";
        case 7:
            return @"x86";
        case 10:
            return @"MC88000";
        case 11:
            return @"HPPA";
        case 12:
        case 16777228:
            return @"arm";
        case 13:
            return @"MC88000";
        case 14:
            return @"Sparc";
        case 15:
            return @"i860";
        case 18:
            return @"PowerPC";
        default:
            return @"Any";
    }
}

- (NSString *)cpuSubType
{
    return [self systemInfoByName:@"hw.cpusubtype"];
}

- (NSString *)cpuArchitectures
{
    NSMutableArray *architectures = [NSMutableArray array];
    
    NSInteger type = [self systemInfoByName:@"hw.cputype"].integerValue;
    NSInteger subtype = [self systemInfoByName:@"hw.cpusubtype"].integerValue;
    
    if (type == CPU_TYPE_X86)
    {
        [architectures addObject:@"x86"];
        
        if (subtype == CPU_SUBTYPE_X86_64_ALL || subtype == CPU_SUBTYPE_X86_64_H)
        {
            [architectures addObject:@"x86_64"];
        }
    }
    else
    {
        if (subtype == CPU_SUBTYPE_ARM_V6)
        {
            [architectures addObject:@"armv6"];
        }
        
        if (subtype == CPU_SUBTYPE_ARM_V7)
        {
            [architectures addObject:@"armv7"];
        }
        
        if (subtype == CPU_SUBTYPE_ARM_V7S)
        {
            [architectures addObject:@"armv7s"];
        }
        
        if (subtype == CPU_SUBTYPE_ARM64_V8 || subtype == CPU_SUBTYPE_ARM64_ALL || subtype == CPU_SUBTYPE_ARM64E)
        {
            [architectures addObject:@"arm64"];
        }
    }
    
    return [architectures componentsJoinedByString:@", "];
}


#pragma mark - Memory Related

- (unsigned long long)memoryMarketingSize
{
    unsigned long long totalSpace = [self memoryPhysicalSize];
    
    double next = pow(2, ceil (log (totalSpace) / log(2)));
    
    return (unsigned long long)next;
    
}

- (unsigned long long)memoryPhysicalSize
{
    return (unsigned long long)[[self systemInfoByName:@"hw.memsize"] longLongValue];
}

#pragma mark - Disk Space Related

- (unsigned long long)diskMarketingSpace
{
    unsigned long long totalSpace = [self diskTotalSpace];
    
    double next = pow(2, ceil (log (totalSpace) / log(2)));
    
    return (unsigned long long)next;
}

- (unsigned long long)diskTotalSpace
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [[fattributes objectForKey:NSFileSystemSize] unsignedLongLongValue];
}

- (unsigned long long)diskFreeSpace
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [[fattributes objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
}

#pragma mark - Device Info

- (NSArray<NSString *> *)urlSchemes
{
    NSMutableArray *urlSchemes = [NSMutableArray array];
    NSArray *array = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    for ( NSDictionary *dict in array ) {
        NSArray *dictSchemes = [dict objectForKey:@"CFBundleURLSchemes"];
        NSString *urlScheme = dictSchemes.count > 0 ? [dictSchemes objectAtIndex:0] : nil;
        if ( urlScheme && urlScheme.length ) {
            [urlSchemes addObject:urlScheme];
        }
    }
    return urlSchemes;
}

- (NSString *)identifierUUID
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (BOOL)isDebug
{
    BOOL isDebug = NO;
#ifdef DEBUG
#if DEBUG
    isDebug = YES;
#endif
#endif
    return isDebug;
}

- (BOOL)isJailbreak
{
#if TARGET_OS_SIMULATOR
    return NO;
#else
    // 1
    NSArray *paths = @[@"/Applications/Cydia.app",
                       @"/private/var/lib/apt/",
                       @"/private/var/lib/cydia",
                       @"/private/var/stash"];
    for (NSString *path in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return YES;
        }
    }
    
    // 2
    FILE *bash = fopen("/bin/bash", "r");
    if (bash != NULL) {
        fclose(bash);
        return YES;
    }
    
    // 3
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString *uuidString = (__bridge_transfer NSString *)string;
    NSString *path = [NSString stringWithFormat:@"/private/%@", uuidString];
    if ([@"test" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return YES;
    }
    
    return NO;
#endif
}

- (NSString *)systemInfoByName:(NSString *)name
{
    const char* typeSpecifier = [name cStringUsingEncoding:NSASCIIStringEncoding];
    
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    NSString *results = nil;
    
    if (size == 4)
    {
        uint32_t *answer = malloc(size);
        sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
        
        uint32_t final = EndianU32_NtoL(*answer);
        
        results = [NSString stringWithFormat:@"%d", final];
        
        free(answer);
    }
    else if (size == 8)
    {
        long long *answer = malloc(size);
        sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
        
        results = [NSString stringWithFormat:@"%lld", *answer];
        
        free(answer);
    }
    else if (size == 0)
    {
        results = @"0";
    }
    else
    {
        char *answer = malloc(size);
        sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
        
        results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
        
        free(answer);
    }
    
    return results;
}

- (NSString *)modelIdentifier
{
    return [self systemInfoByName:@"hw.machine"];
}

#pragma mark - Network

- (NSString *)SSID
{
    return [self fetchSSID][@"SSID"];
}

- (NSString *)BSSID
{
    return [self fetchSSID][@"BSSID"];
}

- (NSString *)macAddress
{
    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0)
    {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL)
    {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3), *(ptr + 4), *(ptr + 5)];
    
    free(buf);
    
    return outstring;
}

- (NSDictionary *)localIPAddresses
{
    NSMutableDictionary *localInterfaces = [NSMutableDictionary dictionary];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    
    if (!getifaddrs(&interfaces))
    {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for (interface = interfaces; interface; interface=interface->ifa_next)
        {
            if (!(interface->ifa_flags & IFF_UP) || (interface->ifa_flags & IFF_LOOPBACK))
            {
                continue; // deeply nested code harder to read
            }
            
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            if(addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6))
            {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                char addrBuf[INET6_ADDRSTRLEN];
                if (inet_ntop(addr->sin_family, &addr->sin_addr, addrBuf, sizeof(addrBuf)))
                {
                    
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, addr->sin_family == AF_INET ? IP_ADDR_IPv4 : IP_ADDR_IPv6];
                    
                    localInterfaces[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [localInterfaces copy];
}

- (NSNumber *)receivedWiFi
{
    return [[self networkDataCounters] objectAtIndex:1];
}

- (NSNumber *)receivedCellular
{
    return [[self networkDataCounters] objectAtIndex:3];
}

- (NSNumber *)sentWifi
{
    return [[self networkDataCounters] objectAtIndex:0];
}

- (NSNumber *)sentCellular
{
    return [[self networkDataCounters] objectAtIndex:2];
}

#pragma mark - Private methods

- (NSDictionary *)fetchSSID
{
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    
    id info = nil;
    
    for (NSString *ifnam in ifs) {
        
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        
        //  CLS_LOG(@"%@ => %@", ifnam, info);
        
        if (info && [info count]) {
            break;
        }
    }
    
    return info;
}

- (NSArray *)networkDataCounters
{
    BOOL success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatistics;
    
    u_int64_t WiFiSent = 0;
    u_int64_t WiFiReceived = 0;
    u_int64_t WWANSent = 0;
    u_int64_t WWANReceived = 0;
    
    NSString *name = nil;
    
    success = getifaddrs(&addrs) == 0;
    
    if (success)
    {
        cursor = addrs;
        
        while (cursor != NULL)
        {
            name = [NSString stringWithFormat:@"%s", cursor->ifa_name];
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatistics = (const struct if_data *) cursor->ifa_data;
                    WiFiSent += networkStatistics->ifi_obytes;
                    WiFiReceived += networkStatistics->ifi_ibytes;
                }
                
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatistics = (const struct if_data *) cursor->ifa_data;
                    WWANSent += networkStatistics->ifi_obytes;
                    WWANReceived += networkStatistics->ifi_ibytes;
                }
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return @[ @(WiFiSent), @(WiFiReceived), @(WWANSent), @(WWANReceived) ];
}

@end
