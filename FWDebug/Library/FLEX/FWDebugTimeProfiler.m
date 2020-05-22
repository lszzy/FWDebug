//
//  FWDebugTimeProfiler.m
//  FWDebug
//
//  Created by wuyong on 2020/5/18.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "FWDebugTimeProfiler.h"
#import "FWDebugAppConfig.h"
#import "FWDebugManager+FWDebug.h"
#import <sys/sysctl.h>
#import <sys/time.h>
#import <objc/runtime.h>

#pragma mark - FWDebugTimeRecord

@interface FWDebugTimeRecord : NSObject

@property (nonatomic, strong) NSMutableArray *recordTimes;

@end

@implementation FWDebugTimeRecord

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recordTimes = [NSMutableArray new];
    }
    return self;
}

- (void)recordEvent:(NSString *)event
{
    [self.recordTimes addObject:[NSArray arrayWithObjects:event, @([FWDebugTimeProfiler currentTime]), nil]];
}

@end

#pragma mark - UIViewController+FWDebugTimeProfiler

@interface UIViewController (FWDebugTimeProfiler)

@end

@implementation UIViewController (FWDebugTimeProfiler)

- (FWDebugTimeRecord *)fwDebugTimeRecord
{
    FWDebugTimeRecord *record = objc_getAssociatedObject(self, _cmd);
    if (!record) {
        record = [[FWDebugTimeRecord alloc] init];
        objc_setAssociatedObject(self, _cmd, record, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return record;
}

- (id)fwDebugInitWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    id object = [self fwDebugInitWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    [self.fwDebugTimeRecord recordEvent:@"↥ init"];
    return object;
}

- (id)fwDebugInitWithCoder:(NSCoder *)coder
{
    id object = [self fwDebugInitWithCoder:coder];
    [self.fwDebugTimeRecord recordEvent:@"↥ init"];
    return object;
}

- (void)fwDebugLoadView
{
    [self.fwDebugTimeRecord recordEvent:@"↧ loadView"];
    [self fwDebugLoadView];
    [self.fwDebugTimeRecord recordEvent:@"↥ loadView"];
}

- (void)fwDebugViewDidLoad
{
    [self.fwDebugTimeRecord recordEvent:@"↧ viewDidLoad"];
    [self fwDebugViewDidLoad];
    [self.fwDebugTimeRecord recordEvent:@"↥ viewDidLoad"];
}

- (void)fwDebugViewWillAppear:(BOOL)animated
{
    [self.fwDebugTimeRecord recordEvent:@"↧ viewWillAppear:"];
    [self fwDebugViewWillAppear:animated];
    [self.fwDebugTimeRecord recordEvent:@"↥ viewWillAppear:"];
}

- (void)fwDebugViewDidAppear:(BOOL)animated
{
    [self.fwDebugTimeRecord recordEvent:@"↧ viewDidAppear:"];
    [self fwDebugViewDidAppear:animated];
    [self.fwDebugTimeRecord recordEvent:@"↥ viewDidAppear:"];
}

@end

#pragma mark - FWDebugTimeProfiler

@interface FWDebugTimeProfiler ()

@property (nonatomic, strong) FWDebugTimeRecord *timeRecord;

@end

@implementation FWDebugTimeProfiler

+ (void)fwDebugLoad
{
    if (![FWDebugAppConfig traceVCLife]) return;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager fwDebugSwizzleMethod:@selector(initWithNibName:bundle:) in:[UIViewController class] with:@selector(fwDebugInitWithNibName:bundle:) in:[UIViewController class]];
        [FWDebugManager fwDebugSwizzleMethod:@selector(initWithCoder:) in:[UIViewController class] with:@selector(fwDebugInitWithCoder:) in:[UIViewController class]];
        [FWDebugManager fwDebugSwizzleMethod:@selector(loadView) in:[UIViewController class] with:@selector(fwDebugLoadView) in:[UIViewController class]];
        [FWDebugManager fwDebugSwizzleMethod:@selector(viewDidLoad) in:[UIViewController class] with:@selector(fwDebugViewDidLoad) in:[UIViewController class]];
        [FWDebugManager fwDebugSwizzleMethod:@selector(viewWillAppear:) in:[UIViewController class] with:@selector(fwDebugViewWillAppear:) in:[UIViewController class]];
        [FWDebugManager fwDebugSwizzleMethod:@selector(viewDidAppear:) in:[UIViewController class] with:@selector(fwDebugViewDidAppear:) in:[UIViewController class]];
    });
}

+ (double)currentTime
{
    struct timeval t0;
    gettimeofday(&t0, NULL);
    return t0.tv_sec + t0.tv_usec * 1e-6;
}

+ (NSTimeInterval)appLaunchedTime
{
    static NSTimeInterval appLaunchedTime;
    if (appLaunchedTime == 0.f) {
        struct kinfo_proc procInfo;
        size_t structSize = sizeof(procInfo);
        int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};

        if (sysctl(mib, sizeof(mib) / sizeof(*mib), &procInfo, &structSize, NULL, 0) != 0) {
            NSLog(@"sysctrl failed");
            appLaunchedTime = [[NSDate date] timeIntervalSince1970];
        } else {
            struct timeval t = procInfo.kp_proc.p_un.__p_starttime;
            appLaunchedTime = t.tv_sec + t.tv_usec * 1e-6;
        }
    }
    return appLaunchedTime;
}

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        _timeRecord = [viewController fwDebugTimeRecord];
        self.title = NSStringFromClass([viewController class]);
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _timeRecord = [[FWDebugTimeRecord alloc] init];
        self.title = @"Time Profiler";
    }
    return self;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.timeRecord.recordTimes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"mm:ss.SSS";
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
    });
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    NSArray *recordTime = self.timeRecord.recordTimes[indexPath.row];
    NSTimeInterval timestamp = [recordTime.lastObject doubleValue];
    cell.textLabel.text = [recordTime.firstObject description];
    cell.detailTextLabel.text = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
    return cell;
}

@end
