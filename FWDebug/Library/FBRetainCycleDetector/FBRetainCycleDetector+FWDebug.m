//
//  FBRetainCycleDetector+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 2017/12/4.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FBRetainCycleDetector+FWDebug.h"
#import "FWDebugAppConfig.h"
#import "FWDebugManager.h"

@implementation FBRetainCycleDetector (FWDebug)

+ (void)fwDebugLaunch
{
    [FBAssociationManager hook];
}

+ (NSSet *)fwDebugRetainCycleWithObject:(id)object
{
    if (!object) {
        return nil;
    }
    
    FBRetainCycleDetector *detector = [[FBRetainCycleDetector alloc] init];
    [detector addCandidate:object];
    return [detector findRetainCyclesWithMaxCycleLength:[FWDebugAppConfig retainCycleDepth]];
}

+ (NSSet *)fwDebugRetainCycleWithObjects:(NSArray *)objects
{
    if (objects.count == 0) {
        return nil;
    }
    
    FBRetainCycleDetector *detector = [[FBRetainCycleDetector alloc] init];
    for (id object in objects) {
        [detector addCandidate:object];
    }
    return [detector findRetainCyclesWithMaxCycleLength:[FWDebugAppConfig retainCycleDepth]];
}

@end
