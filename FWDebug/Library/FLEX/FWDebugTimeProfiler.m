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
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) NSUInteger selectedRow;
@property (nonatomic, copy) NSString *costText;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"mm:ss.SSS";
    self.dateFormatter.timeZone = [NSTimeZone localTimeZone];
    
    self.tableView.allowsMultipleSelection = YES;
    self.selectedRow = NSNotFound;
    self.costText = @"Please select a time range";
}

#pragma mark - UITableView

- (BOOL)isLastIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row == self.timeRecord.recordTimes.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.timeRecord.recordTimes.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLastIndexPath:indexPath]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell2"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell2"];
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        }
        cell.textLabel.text = self.costText;
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    }
    NSArray *firstTime = self.timeRecord.recordTimes.firstObject;
    NSArray *recordTime = self.timeRecord.recordTimes[indexPath.row];
    NSString *timeText = [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[recordTime.lastObject doubleValue]]];
    NSTimeInterval timeInterval = [recordTime.lastObject doubleValue] - [firstTime.lastObject doubleValue];
    cell.textLabel.text = [recordTime.firstObject description];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%.3lfms)", timeText, timeInterval * 1000];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLastIndexPath:indexPath]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    NSUInteger selectedRow = indexPath.row;
    if (self.selectedRow == NSNotFound) {
        for (NSIndexPath *aIndexPath in [tableView indexPathsForSelectedRows]) {
            if ([aIndexPath compare:indexPath] == NSOrderedSame) {
                continue;
            }
            [tableView deselectRowAtIndexPath:aIndexPath animated:YES];
        }
        self.costText = @"Select another time";
        self.selectedRow = selectedRow;
    } else {
        NSUInteger minRow = MIN(self.selectedRow, selectedRow);
        NSUInteger maxRow = MAX(self.selectedRow, selectedRow);
        for (NSUInteger aRow = minRow; aRow <= maxRow; aRow++) {
            NSIndexPath *indexPathToSelect = [NSIndexPath indexPathForRow:aRow inSection:0];
            [tableView selectRowAtIndexPath:indexPathToSelect animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
        NSArray *startRecord = self.timeRecord.recordTimes[minRow];
        NSArray *endRecord = self.timeRecord.recordTimes[maxRow];
        NSTimeInterval timeInterval = [endRecord.lastObject doubleValue] - [startRecord.lastObject doubleValue];
        self.costText = [NSString stringWithFormat:@"Cost：%.3lfms", timeInterval * 1000];
        self.selectedRow = NSNotFound;
    }
    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.timeRecord.recordTimes.count inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLastIndexPath:indexPath]) return;
    
    NSUInteger selectedRow = indexPath.row;
    if (self.selectedRow == NSNotFound) {
        for (NSIndexPath *aIndexPath in [tableView indexPathsForSelectedRows]) {
            [tableView deselectRowAtIndexPath:aIndexPath animated:YES];
        }
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        self.costText = @"Select another time";
        self.selectedRow = selectedRow;
    } else {
        self.costText = @"Please select a time range";
        self.selectedRow = NSNotFound;
    }
    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.timeRecord.recordTimes.count inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

@end
