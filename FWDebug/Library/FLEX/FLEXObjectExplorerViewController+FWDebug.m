//
//  FLEXObjectExplorerViewController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXObjectExplorerViewController+FWDebug.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import "FLEXAlert.h"
#import "RTBClass.h"
#import "FWDebugManager+FWDebug.h"
#import "FWDebugRuntimeBrowser.h"
#import "FWDebugRetainCycle.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import <malloc/malloc.h>

@implementation FLEXObjectExplorerViewController (FWDebug)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager fwDebugSwizzleMethod:@selector(viewDidLoad) in:self with:@selector(fwDebugViewDidLoad) in:self];
    });
}

#pragma mark - FWDebug

- (void)fwDebugViewDidLoad
{
    [self fwDebugViewDidLoad];
    
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(fwDebugSearchPressed:)];
    if (self.navigationItem.rightBarButtonItems.count > 0) {
        NSMutableArray *rightItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
        [rightItems addObject:searchItem];
        self.navigationItem.rightBarButtonItems = rightItems;
    } else {
        self.navigationItem.rightBarButtonItem = searchItem;
    }
}

- (void)fwDebugSearchPressed:(UIBarButtonItem *)sender
{
    if (self.explorer.objectIsInstance) {
        [self fwDebugRetainCycles];
    } else {
        [FLEXAlert makeSheet:^(FLEXAlert *make) {
            make.button(@"Retain Cycles").handler(^(NSArray<NSString *> *strings) {
                [self fwDebugRetainCycles];
            });
            make.button(@"Runtime Headers").handler(^(NSArray<NSString *> *strings) {
                [self fwDebugRuntimeHeaders];
            });
            make.button(@"Cancel").cancelStyle();
        } showFrom:self source:sender];
    }
}

- (void)fwDebugRuntimeHeaders
{
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        Class objectClass = [self.object class];
        RTBClass *classStub = [RTBClass classStubWithClass:objectClass];
        NSArray *classProtocols = [classStub sortedProtocolsNames];
        
        make.button([NSString stringWithFormat:@"%@.h", [objectClass description]]).handler(^(NSArray<NSString *> *strings) {
            UIViewController *viewController = [[FWDebugRuntimeBrowser alloc] initWithClassName:[objectClass description]];
            [self.navigationController pushViewController:viewController animated:YES];
        });
        for (NSString *protocolName in classProtocols) {
            make.button([NSString stringWithFormat:@"%@.h", protocolName]).handler(^(NSArray<NSString *> *strings) {
                UIViewController *viewController = [[FWDebugRuntimeBrowser alloc] initWithProtocolName:protocolName];
                [self.navigationController pushViewController:viewController animated:YES];
            });
        }
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:nil];
}

- (void)fwDebugRetainCycles
{
    NSSet *retainCycles = nil;
    if (self.explorer.objectIsInstance) {
        retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObject:self.object];
    } else {
        NSString *className = NSStringFromClass(object_getClass(self.object));
        const char *classNameCString = className.UTF8String;
        NSMutableArray *instances = [NSMutableArray new];
        [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
            if (strcmp(classNameCString, class_getName(actualClass)) == 0) {
                if (malloc_size((__bridge const void *)(object)) > 0) {
                    [instances addObject:object];
                }
            }
        }];
        
        NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingAll:instances];
        retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObjects:references];
    }
    
    FWDebugRetainCycle *viewController = [[FWDebugRetainCycle alloc] init];
    viewController.retainCycles = [retainCycles allObjects];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
