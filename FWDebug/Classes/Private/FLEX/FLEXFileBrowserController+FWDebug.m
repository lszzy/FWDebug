//
//  FLEXFileBrowserController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/24.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXFileBrowserController+FWDebug.h"
#import "FLEXMacros.h"
#import "FWDebugManager+FWDebug.h"
#import <objc/runtime.h>

static NSString *fwDebugCopyPath = nil;

@interface FLEXFileBrowserController ()

- (void)fileBrowserRename:(UITableViewCell *)sender;
- (void)fileBrowserDelete:(UITableViewCell *)sender;
- (void)fileBrowserCopyPath:(UITableViewCell *)sender;
- (void)fileBrowserShare:(UITableViewCell *)sender;

@end

@implementation FLEXFileBrowserController (FWDebug)

+ (void)fwDebugLoad
{
    [FWDebugManager swizzleMethod:@selector(tableView:shouldShowMenuForRowAtIndexPath:) in:[FLEXFileBrowserController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^BOOL(__unsafe_unretained FLEXFileBrowserController *selfObject, UITableView *tableView, NSIndexPath *indexPath) {
            BOOL shouldShow = ((BOOL (*)(id, SEL, UITableView *, NSIndexPath *))originalIMP())(selfObject, originalCMD, tableView, indexPath);
            
            NSMutableArray<UIMenuItem *> *menuItems = [NSMutableArray arrayWithArray:[UIMenuController sharedMenuController].menuItems];
            selfObject.fwDebugCopyItem.title = fwDebugCopyPath ? @"Paste" : @"Copy";
            [menuItems addObject:selfObject.fwDebugCopyItem];
            [UIMenuController sharedMenuController].menuItems = menuItems;
            return shouldShow;
        };
    }];
    
    [FWDebugManager swizzleMethod:@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:) in:[FLEXFileBrowserController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^BOOL(__unsafe_unretained FLEXFileBrowserController *selfObject, UITableView *tableView, SEL action, NSIndexPath *indexPath, id sender) {
            BOOL canPerform = ((BOOL (*)(id, SEL, UITableView *, SEL, NSIndexPath *, id))originalIMP())(selfObject, originalCMD, tableView, action, indexPath, sender);
            
            return canPerform || action == @selector(fwDebugFileBrowserCopy:);
        };
    }];
    
    if (@available(iOS 13.0, *)) {
        [FWDebugManager swizzleMethod:@selector(tableView:contextMenuConfigurationForRowAtIndexPath:point:) in:[FLEXFileBrowserController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^UIContextMenuConfiguration *(__unsafe_unretained FLEXFileBrowserController *selfObject, UITableView *tableView, NSIndexPath *indexPath, CGPoint point) {
                return [selfObject fwDebugTableView:tableView contextMenuConfigurationForRowAtIndexPath:indexPath point:point];
            };
        }];
    }
}

#pragma mark - FWDebug

- (UIMenuItem *)fwDebugCopyItem
{
    UIMenuItem *item = objc_getAssociatedObject(self, _cmd);
    if (!item) {
        item = [[UIMenuItem alloc] initWithTitle:@"" action:@selector(fwDebugFileBrowserCopy:)];
        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)fwDebugFileBrowserCopy:(UITableViewCell *)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    SEL selector = NSSelectorFromString(@"filePathAtIndexPath:");
    NSString *fullPath = [self performSelector:selector withObject:indexPath];
    
    if (fwDebugCopyPath) {
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
        NSString *targetPath;
        if (isDirectory) {
            targetPath = [fullPath stringByAppendingPathComponent:fwDebugCopyPath.lastPathComponent];
        } else {
            targetPath = [[fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fwDebugCopyPath.lastPathComponent];
        }
        if (![targetPath isEqualToString:fwDebugCopyPath] &&
            ![[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
            [[NSFileManager defaultManager] copyItemAtPath:fwDebugCopyPath toPath:targetPath error:NULL];
            selector = NSSelectorFromString(@"reloadDisplayedPaths");
            [self performSelector:selector];
        }
        
        fwDebugCopyPath = nil;
        self.fwDebugCopyItem.title = @"Copy";
    } else {
        fwDebugCopyPath = fullPath;
        self.fwDebugCopyItem.title = @"Paste";
    }
#pragma clang diagnostic pop
}

- (UIContextMenuConfiguration *)fwDebugTableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point __IOS_AVAILABLE(13.0) {
    __weak typeof(self) weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                   previewProvider:nil
                                                    actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UITableViewCell * const cell = [tableView cellForRowAtIndexPath:indexPath];
        UIAction *rename = [UIAction actionWithTitle:@"Rename"
                                               image:nil
                                          identifier:@"Rename"
                                             handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf fileBrowserRename:cell];
        }];
        UIAction *delete = [UIAction actionWithTitle:@"Delete"
                                               image:nil
                                          identifier:@"Delete"
                                             handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf fileBrowserDelete:cell];
        }];
        UIAction *copyPath = [UIAction actionWithTitle:@"Copy Path"
                                                 image:nil
                                            identifier:@"Copy Path"
                                               handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf fileBrowserCopyPath:cell];
        }];
        UIAction *share = [UIAction actionWithTitle:@"Share"
                                              image:nil
                                         identifier:@"Share"
                                            handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf fileBrowserShare:cell];
        }];
        UIAction *copy = [UIAction actionWithTitle:fwDebugCopyPath ? @"Paste" : @"Copy"
                                              image:nil
                                         identifier:fwDebugCopyPath ? @"Paste" : @"Copy"
                                            handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf fwDebugFileBrowserCopy:cell];
        }];
        return [UIMenu menuWithTitle:@"Manage File" image:nil identifier:@"Manage File" options:UIMenuOptionsDisplayInline children:@[rename, delete, copyPath, share, copy]];
    }];
}

@end

#pragma mark - FLEXFileBrowserTableViewCell+FWDebug

@interface FLEXFileBrowserTableViewCell : UITableViewCell

@end

@interface FLEXFileBrowserTableViewCell (FWDebug)

@end

@implementation FLEXFileBrowserTableViewCell (FWDebug)

- (void)fwDebugFileBrowserCopy:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}

@end
