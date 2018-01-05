//
//  FLEXFileBrowserTableViewController+FWDebugFLEX.m
//  FWDebug
//
//  Created by wuyong on 17/2/24.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FLEXFileBrowserTableViewController+FWDebug.h"
#import "FWDebugManager+FWDebug.h"
#import <objc/runtime.h>

static NSString *fwDebugCopyPath = nil;

@implementation FLEXFileBrowserTableViewController (FWDebug)

+ (void)load
{
    [FWDebugManager fwDebugSwizzleInstance:self method:@selector(viewDidLoad) with:@selector(fwDebugViewDidLoad)];
    [FWDebugManager fwDebugSwizzleInstance:self method:@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:) with:@selector(fwDebugTableView:canPerformAction:forRowAtIndexPath:withSender:)];
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

- (void)fwDebugViewDidLoad
{
    [self fwDebugViewDidLoad];
    
    NSMutableArray<UIMenuItem *> *menuItems = [NSMutableArray arrayWithArray:[UIMenuController sharedMenuController].menuItems];
    self.fwDebugCopyItem.title = fwDebugCopyPath ? @"Paste" : @"Copy";
    [menuItems addObject:self.fwDebugCopyItem];
    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"Openin" action:@selector(fwDebugFileBrowserOpenin:)]];
    [UIMenuController sharedMenuController].menuItems = menuItems;
}

- (BOOL)fwDebugTableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    BOOL result = [self fwDebugTableView:tableView canPerformAction:action forRowAtIndexPath:indexPath withSender:sender];
    return result || action == @selector(fwDebugFileBrowserOpenin:) || action == @selector(fwDebugFileBrowserCopy:);
}

- (void)fwDebugFileBrowserOpenin:(UITableViewCell *)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    SEL selector = NSSelectorFromString(@"filePathAtIndexPath:");
    NSString *fullPath = [self performSelector:selector withObject:indexPath];
    
    selector = NSSelectorFromString(@"openFileController:");
    [self performSelector:selector withObject:fullPath];
#pragma clang diagnostic pop
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

@end

#pragma mark - FLEXFileBrowserTableViewCell+FWDebug

@interface FLEXFileBrowserTableViewCell : UITableViewCell

@end

@interface FLEXFileBrowserTableViewCell (FWDebug)

@end

@implementation FLEXFileBrowserTableViewCell (FWDebug)

- (void)fwDebugFileBrowserOpenin:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}

- (void)fwDebugFileBrowserCopy:(UIMenuController *)sender
{
    id target = [self.nextResponder targetForAction:_cmd withSender:sender];
    [[UIApplication sharedApplication] sendAction:_cmd to:target from:self forEvent:nil];
}

@end
