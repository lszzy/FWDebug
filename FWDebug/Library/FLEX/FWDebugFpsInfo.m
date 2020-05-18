//
//  FWDebugFpsInfo.m
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugFpsInfo.h"
#import "FLEXWindow.h"
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
        _fpsData.fps = 0;
        _fpsData.fpsState = 0;
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
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if ([keyWindow isKindOfClass:[FLEXWindow class]]) {
        return;
    }

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
    return (memory < 100.0) ? 1 : (memory < 200.0 ? 0 : -1);
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
    
    // 同NSByteCountFormatter，取1000
    return memory / 1000.0 / 1000.0;
}

- (float)cpuUsage
{
    double totalUsageRatio = 0;
    double maxRatio = 0;

    thread_info_data_t thinfo;
    thread_act_array_t threads;
    thread_basic_info_t basic_info_t;
    mach_msg_type_number_t count = 0;
    mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;

    if (task_threads(mach_task_self(), &threads, &count) == KERN_SUCCESS) {
        for (int idx = 0; idx < count; idx++) {
            if (thread_info(threads[idx], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count) == KERN_SUCCESS) {
                basic_info_t = (thread_basic_info_t)thinfo;

                if (!(basic_info_t->flags & TH_FLAGS_IDLE)) {
                    double cpuUsage = basic_info_t->cpu_usage / (double)TH_USAGE_SCALE;
                    if (cpuUsage > maxRatio) {
                        maxRatio = cpuUsage;
                    }
                    totalUsageRatio += cpuUsage;
                }
            }
        }

        assert(vm_deallocate(mach_task_self(), (vm_address_t)threads, count * sizeof(thread_t)) == KERN_SUCCESS);
    }
    return totalUsageRatio * 100.f;
}

@end
