//
//  FWDebugRetainCycle.m
//  FWDebug
//
//  Created by wuyong on 2017/12/4.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugRetainCycle.h"
#import "FBRetainCycleDetector.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"

@interface FWDebugRetainCycle ()

@property (nonatomic, assign) BOOL isDetail;

@end

@implementation FWDebugRetainCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = !self.isDetail ? @"Retain Cycles" : [self.retainCycles[0] classNameOrNull];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.retainCycles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    }
    
    if (!self.isDetail) {
        NSArray<FBObjectiveCGraphElement *> *retainCycle = self.retainCycles[indexPath.row];
        cell.textLabel.text = [retainCycle[0] classNameOrNull];
    } else {
        cell.textLabel.text = [self.retainCycles[indexPath.row] description];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.isDetail) {
        FWDebugRetainCycle *viewController = [[FWDebugRetainCycle alloc] init];
        viewController.isDetail = YES;
        viewController.retainCycles = [self.retainCycles objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        FBObjectiveCGraphElement *element = [self.retainCycles objectAtIndex:indexPath.row];
        if (element.object) {
            FLEXObjectExplorerViewController *viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:element.object];
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

@end
