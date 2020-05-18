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

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager fwDebugSwizzleMethod:@selector(tableView:shouldShowMenuForRowAtIndexPath:) in:self with:@selector(fwDebugTableView:shouldShowMenuForRowAtIndexPath:) in:self];
        [FWDebugManager fwDebugSwizzleMethod:@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:) in:self with:@selector(fwDebugTableView:canPerformAction:forRowAtIndexPath:withSender:) in:self];
#if FLEX_AT_LEAST_IOS13_SDK
        if (@available(iOS 13.0, *)) {
            [FWDebugManager fwDebugSwizzleMethod:@selector(tableView:contextMenuConfigurationForRowAtIndexPath:point:) in:self with:@selector(fwDebugTableView:contextMenuConfigurationForRowAtIndexPath:point:) in:self];
        }
#endif
    });
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

- (BOOL)fwDebugTableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL result = [self fwDebugTableView:tableView shouldShowMenuForRowAtIndexPath:indexPath];
    NSMutableArray<UIMenuItem *> *menuItems = [NSMutableArray arrayWithArray:[UIMenuController sharedMenuController].menuItems];
    self.fwDebugCopyItem.title = fwDebugCopyPath ? @"Paste" : @"Copy";
    [menuItems addObject:self.fwDebugCopyItem];
    [UIMenuController sharedMenuController].menuItems = menuItems;
    return result;
}

- (BOOL)fwDebugTableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    BOOL result = [self fwDebugTableView:tableView canPerformAction:action forRowAtIndexPath:indexPath withSender:sender];
    return result || action == @selector(fwDebugFileBrowserCopy:);
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

#if FLEX_AT_LEAST_IOS13_SDK
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
#endif

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
