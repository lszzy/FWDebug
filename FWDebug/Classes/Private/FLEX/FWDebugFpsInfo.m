//
//  FWDebugFpsInfo.m
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugFpsInfo.h"
#import "FLEXManager.h"
#import <UIKit/UIKit.h>
#import <mach/mach.h>

// 解决NSTimer导致的self循环引用问题
@interface FWDebugWeakProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;

@end

@implementation FWDebugWeakProxy

- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}

@end

@implementation FWDebugFpsData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fps = 0;
        _fpsState = 1;
        _memory = 0;
        _memoryState = 1;
        _cpu = 0;
        _cpuState = 1;
    }
    return self;
}

@end

@interface FWDebugFpsInfo ()

@property (strong, nonatomic) CADisplayLink * displayLink;

@property (assign, nonatomic) NSTimeInterval lastTimestamp;

@property (assign, nonatomic) NSInteger countPerFrame;

@end

@implementation FWDebugFpsInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fpsData = [[FWDebugFpsData alloc] init];
        _fpsData.memory = [self memoryUsage];
        _fpsData.memoryState = [self memoryStateForData:_fpsData.memory];
        _fpsData.cpu = [self cpuUsage];
        _fpsData.cpuState = [self cpuStateForData:_fpsData.cpu];
        
        _lastTimestamp = -1;
        _displayLink = [CADisplayLink displayLinkWithTarget:[[FWDebugWeakProxy alloc] initWithTarget:self] selector:@selector(onDisplay:)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onResign)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [_displayLink invalidate];
}

- (void)start
{
    _displayLink.paused = NO;
}

- (void)stop
{
    _displayLink.paused = YES;
}

- (void)onDisplay:(CADisplayLink *)displayLink
{
    if (_lastTimestamp == -1) {
        _lastTimestamp = displayLink.timestamp;
        return;
    }
    
    _countPerFrame ++;
    NSTimeInterval interval = displayLink.timestamp - _lastTimestamp;
    if (interval < 1) {
        return;
    }
    
    if ([FLEXManager sharedManager].isHidden) return;

    _lastTimestamp = displayLink.timestamp;
    CGFloat fps = _countPerFrame / interval;
    _countPerFrame = 0;
    _fpsData.fps = fps;
    _fpsData.fpsState = [self fpsStateForData:fps];
    
    CGFloat cpu = [self cpuUsage];
    _fpsData.cpu = cpu;
    _fpsData.cpuState = [self cpuStateForData:cpu];
    
    CGFloat memory = [self memoryUsage];
    _fpsData.memory = memory;
    _fpsData.memoryState = [self memoryStateForData:_fpsData.memory];

    if (self.delegate && [self.delegate respondsToSelector:@selector(fwDebugFpsInfoChanged:)]) {
        [self.delegate fwDebugFpsInfoChanged:_fpsData];
    }
}

- (void)onActive
{
    _displayLink.paused = NO;
}

- (void)onResign
{
    _displayLink.paused = YES;
}

#pragma mark - Private

- (NSInteger)fpsStateForData:(float)fps
{
    return (fps > 50.0) ? 1 : (fps > 40.0 ? 0 : -1);
}

- (NSInteger)memoryStateForData:(float)memory
{
    CGFloat memoryTotal = [self memoryTotal];
    if (memoryTotal <= 0) return 1;
    return (memory < memoryTotal * 0.2) ? 1 : (memory < memoryTotal * 0.3 ? 0 : -1);
}

- (NSInteger)cpuStateForData:(float)cpu
{
    return (cpu < 70.0) ? 1 : (cpu < 90.0 ? 0 : -1);
}

- (float)memoryUsage
{
    // The real physical memory used by app，参考自MTHawkeye
    task_vm_info_data_t vmInfo;
    vmInfo.phys_footprint = 0;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
    int64_t memory = (result == KERN_SUCCESS) ? vmInfo.phys_footprint : 0;
    
    // Used memory by app in byte
    if (memory == 0) {
        struct task_basic_info info;
        mach_msg_type_number_t size = (sizeof(task_basic_info_data_t) / sizeof(natural_t));
        kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
        memory = (kerr == KERN_SUCCESS) ? info.resident_size : 0;
    }
    
    return memory / 1024.0 / 1024.0;
}

- (float)memoryTotal
{
    static float memoryTotal = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int64_t memorySize = [[NSProcessInfo processInfo] physicalMemory];
        if (memorySize < -1) memorySize = -1;
        memoryTotal = memorySize / 1024.0 / 1024.0;
    });
    return memoryTotal;
}

- (float)cpuUsage
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

@end
