//
//  FBRetainCycleDetector+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 2017/12/4.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FBRetainCycleDetector+FWDebug.h"
#import "FWDebugAppSecret.h"
#import "FWDebugManager.h"

@implementation FBRetainCycleDetector (FWDebug)

+ (void)fwDebugLaunch
{
    [FBAssociationManager hook];
}

+ (FBRetainCycleDetector *)fwDebugRetainCycleDetector
{
    NSMutableArray *filterBlocks = [NSMutableArray arrayWithArray:FBGetStandardGraphEdgeFilters()];
    // 添加自定义过滤block
    if ([FWDebugManager sharedInstance].retainCycleFilter) {
        FBGraphEdgeFilterBlock customFilter = ^(FBObjectiveCGraphElement *fromObject,
                                                NSString *byIvar,
                                                Class toObjectOfClass) {
            FBGraphEdgeType filterResult = FBGraphEdgeValid;
            if ([FWDebugManager sharedInstance].retainCycleFilter) {
                filterResult = [FWDebugManager sharedInstance].retainCycleFilter([fromObject objectClass], byIvar, toObjectOfClass) ? FBGraphEdgeValid : FBGraphEdgeInvalid;
            }
            return filterResult;
        };
        [filterBlocks addObject:customFilter];
    }
    
    FBObjectGraphConfiguration *configuration = [[FBObjectGraphConfiguration alloc] initWithFilterBlocks:filterBlocks shouldInspectTimers:YES];
    return [[FBRetainCycleDetector alloc] initWithConfiguration:configuration];
}

+ (NSSet *)fwDebugRetainCycleWithObject:(id)object
{
    if (!object) {
        return nil;
    }
    
    FBRetainCycleDetector *detector = [self fwDebugRetainCycleDetector];
    [detector addCandidate:object];
    return [detector findRetainCyclesWithMaxCycleLength:[FWDebugAppSecret retainCycleDepth]];
}

+ (NSSet *)fwDebugRetainCycleWithObjects:(NSArray *)objects
{
    if (objects.count < 0) {
        return nil;
    }
    
    FBRetainCycleDetector *detector = [self fwDebugRetainCycleDetector];
    for (id object in objects) {
        [detector addCandidate:object];
    }
    return [detector findRetainCyclesWithMaxCycleLength:[FWDebugAppSecret retainCycleDepth]];
}

@end
