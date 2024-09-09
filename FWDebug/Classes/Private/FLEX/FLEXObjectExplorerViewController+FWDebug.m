//
//  FLEXObjectExplorerViewController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXObjectExplorerViewController+FWDebug.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXSingleRowSection.h"
#import "FLEXTableViewCell.h"
#import "FLEXUtility.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import "FLEXAlert.h"
#import "RTBClass.h"
#import "FWDebugManager+FWDebug.h"
#import "FWDebugRuntimeBrowser.h"
#import "FWDebugRetainCycle.h"
#import "FWDebugTimeProfiler.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import <malloc/malloc.h>

static NSMutableArray *fwDebugCustomObjectEntries = nil;

@interface FWDebugCustomObjectEntry : NSObject

@property (nonatomic, copy) NSString *entryName;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) BOOL (^filter)(id object);
@property (nonatomic, copy) void (^actionBlock)(__kindof UIViewController *viewController, id object);

@end

@implementation FWDebugCustomObjectEntry

@end

@interface FLEXObjectExplorerViewController ()

@property (nonatomic, readonly) FLEXSingleRowSection *descriptionSection;

@end

@implementation FLEXObjectExplorerViewController (FWDebug)

+ (void)fwDebugLoad
{
    [FWDebugManager swizzleMethod:@selector(viewDidLoad) in:[FLEXObjectExplorerViewController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^(__unsafe_unretained FLEXObjectExplorerViewController *selfObject) {
            ((void (*)(id, SEL))originalIMP())(selfObject, originalCMD);
            
            [selfObject fwDebugSearchItem];
        };
    }];
    
    [FWDebugManager swizzleMethod:@selector(makeSections) in:[FLEXObjectExplorerViewController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^NSArray<FLEXTableViewSection *> *(__unsafe_unretained FLEXObjectExplorerViewController *selfObject) {
            NSArray *originSections = ((NSArray *(*)(id, SEL))originalIMP())(selfObject, originalCMD);
            
            return [selfObject fwDebugMakeSections:originSections];
        };
    }];
}

+ (void)fwDebugRegisterEntry:(NSString *)entryName title:(NSString *)title filter:(BOOL (^)(id _Nonnull))filter actionBlock:(void (^)(__kindof UIViewController * _Nonnull, id _Nonnull))actionBlock
{
    FWDebugCustomObjectEntry *entry = [FWDebugCustomObjectEntry new];
    entry.entryName = entryName;
    entry.title = title;
    entry.filter = filter;
    entry.actionBlock = actionBlock;
    
    if (!fwDebugCustomObjectEntries) {
        fwDebugCustomObjectEntries = [NSMutableArray new];
    }
    [fwDebugCustomObjectEntries addObject:entry];
}

+ (void)fwDebugRemoveEntry:(NSString *)entryName
{
    if (!fwDebugCustomObjectEntries) return;
    
    NSMutableArray *removeEntries = [NSMutableArray new];
    for (FWDebugCustomObjectEntry *entry in fwDebugCustomObjectEntries) {
        if ([entry.entryName isEqualToString:entryName]) {
            [removeEntries addObject:entry];
        }
    }
    [fwDebugCustomObjectEntries removeObjectsInArray:removeEntries];
}

#pragma mark - FWDebug

- (void)fwDebugSearchItem
{
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(fwDebugRetainCycles)];
    if (self.navigationItem.rightBarButtonItems.count > 0) {
        NSMutableArray *rightItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
        [rightItems addObject:searchItem];
        self.navigationItem.rightBarButtonItems = rightItems;
    } else {
        self.navigationItem.rightBarButtonItem = searchItem;
    }
}

- (NSArray<FLEXTableViewSection *> *)fwDebugMakeSections:(NSArray *)originSections
{
    NSMutableArray *sections = [NSMutableArray arrayWithArray:originSections];
    FLEXObjectExplorer *explorer = self.explorer;
    if (explorer.objectIsInstance) {
        if (self.descriptionSection) {
            self.descriptionSection.selectionAction = ^(UIViewController *host) {
                FLEXObjectExplorerViewController *viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:[explorer.object class]];
                [host.navigationController pushViewController:viewController animated:YES];
            };
        }
        
        FLEXSingleRowSection *customSection = [FLEXSingleRowSection title:@"Time Profiler" reuse:kFLEXDefaultCell cell:^(FLEXTableViewCell *cell) {
            cell.titleLabel.font = UIFont.flex_defaultTableCellFont;
            cell.titleLabel.text = @"Time Profiler";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }];
        customSection.filterMatcher = ^BOOL(NSString *filterText) {
            return [@"Time Profiler" localizedCaseInsensitiveContainsString:filterText];
        };
        customSection.selectionAction = ^(UIViewController *host) {
            FWDebugTimeProfiler *viewController = [[FWDebugTimeProfiler alloc] initWithObject:explorer.object];
            [host.navigationController pushViewController:viewController animated:YES];
        };
        [sections insertObject:customSection atIndex:0];
    } else {
        FLEXSingleRowSection *customSection = [FLEXSingleRowSection title:@"Runtime Headers" reuse:kFLEXDefaultCell cell:^(FLEXTableViewCell *cell) {
            cell.titleLabel.font = UIFont.flex_defaultTableCellFont;
            cell.titleLabel.text = @"Runtime Headers";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }];
        customSection.filterMatcher = ^BOOL(NSString *filterText) {
            return [@"Runtime Headers" localizedCaseInsensitiveContainsString:filterText];
        };
        customSection.selectionAction = ^(UIViewController *host) {
            [FLEXAlert makeSheet:^(FLEXAlert *make) {
                Class objectClass = [explorer.object class];
                RTBClass *classStub = [RTBClass classStubWithClass:objectClass];
                NSArray *classProtocols = [classStub sortedProtocolsNames];
                
                make.button([NSString stringWithFormat:@"%@.h", [objectClass description]]).handler(^(NSArray<NSString *> *strings) {
                    UIViewController *viewController = [[FWDebugRuntimeBrowser alloc] initWithClassName:[objectClass description]];
                    [host.navigationController pushViewController:viewController animated:YES];
                });
                for (NSString *protocolName in classProtocols) {
                    make.button([NSString stringWithFormat:@"%@.h", protocolName]).handler(^(NSArray<NSString *> *strings) {
                        UIViewController *viewController = [[FWDebugRuntimeBrowser alloc] initWithProtocolName:protocolName];
                        [host.navigationController pushViewController:viewController animated:YES];
                    });
                }
                make.button(@"Cancel").cancelStyle();
            } showFrom:host source:nil];
        };
        [sections insertObject:customSection atIndex:0];
    }
    
    if (fwDebugCustomObjectEntries) {
        for (FWDebugCustomObjectEntry *entry in [fwDebugCustomObjectEntries reverseObjectEnumerator]) {
            if (entry.filter && !entry.filter(explorer.object)) continue;
            
            FLEXSingleRowSection *customSection = [FLEXSingleRowSection title:entry.title reuse:kFLEXDefaultCell cell:^(FLEXTableViewCell *cell) {
                cell.titleLabel.font = UIFont.flex_defaultTableCellFont;
                cell.titleLabel.text = entry.entryName;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }];
            customSection.filterMatcher = ^BOOL(NSString *filterText) {
                return [entry.entryName localizedCaseInsensitiveContainsString:filterText];
            };
            customSection.selectionAction = ^(UIViewController *host) {
                if (entry.actionBlock) {
                    entry.actionBlock(host, explorer.object);
                }
            };
            [sections insertObject:customSection atIndex:0];
        }
    }
    return sections.copy;
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
        
        NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingAll:instances retained:NO];
        retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObjects:references];
    }
    
    FWDebugRetainCycle *viewController = [[FWDebugRetainCycle alloc] init];
    viewController.retainCycles = [retainCycles allObjects];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
