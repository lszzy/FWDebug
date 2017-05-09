//
//  FWDebugAppList.m
//  FWDebug
//
//  Created by wuyong on 17/3/8.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugAppList.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import <objc/runtime.h>

#pragma mark - Private Headers

// LSApplicationProxy.h
@interface LSBundleProxy
@property (nonatomic, readonly) NSString *localizedShortName;
@end

@interface LSApplicationProxy : LSBundleProxy <NSSecureCoding>
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSArray *appTags;
@end

// LSApplicationWorkspace.h
typedef NS_ENUM(NSUInteger, _ApplicationType) { $_LSUserApplicationType, $_LSSystemApplicationType, $_LSInternalApplicationType };

@interface LSApplicationWorkspace
+ (instancetype)defaultWorkspace;
- (id)applicationsOfType:(_ApplicationType)arg1;
@end

// UIImage+UIApplicationIconPrivate.h
@interface UIImage (UIApplicationIconPrivate)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

#pragma mark - FWDebugAppList

@interface FWDebugAppList () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *userAppList;
@property (nonatomic, strong) NSArray *systemAppList;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSString *filterText;
@property (nonatomic, assign) NSInteger filterType;

@property (nonatomic, strong) NSMutableArray *tableData;

@end

@implementation FWDebugAppList

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"System Apps";
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"Filter";
    self.searchBar.delegate = self;
    self.searchBar.showsScopeBar = YES;
    self.searchBar.scopeButtonTitles = @[@"User", @"System"];
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlDidRefresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateTableData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar endEditing:YES];
}

- (void)refreshControlDidRefresh:(id)sender
{
    [self updateTableData];
    [self.refreshControl endRefreshing];
}

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filterText = searchText;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    self.filterType = selectedScope == 1 ? 1 : 0;
}

#pragma mark - Setter overrides

- (void)setFilterText:(NSString *)filterText
{
    if (_filterText != filterText || ![_filterText isEqual:filterText]) {
        _filterText = filterText;
        [self updateDisplayedData];
    }
}

- (void)setFilterType:(NSInteger)filterType
{
    if (_filterType != filterType) {
        _filterType = filterType;
        [self updateDisplayedData];
    }
}

#pragma mark - Private

- (void)updateTableData
{
    //User
    _ApplicationType appType = $_LSUserApplicationType;
    self.userAppList = [self appOfType:appType];
    
    //System
    appType = $_LSSystemApplicationType;
    self.systemAppList = [self appOfType:appType];
    
    [self updateDisplayedData];
}

- (void)updateDisplayedData
{
    NSMutableArray *tableData = [NSMutableArray array];
    
    NSArray *appList = self.filterType == 1 ? self.systemAppList : self.userAppList;
    if (self.filterText.length < 1) {
        [tableData addObjectsFromArray:appList];
    } else {
        for (NSDictionary *cellData in appList) {
            if ([[cellData objectForKey:@"title"] rangeOfString:self.filterText].location != NSNotFound ||
                [[cellData objectForKey:@"subtitle"] rangeOfString:self.filterText].location != NSNotFound) {
                [tableData addObject:cellData];
            }
        }
    }
    
    self.tableData = tableData;
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (NSArray *)appOfType:(_ApplicationType)appType
{
    NSArray* apps = [[objc_getClass("LSApplicationWorkspace") defaultWorkspace] applicationsOfType:appType];
    apps = [apps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(LSApplicationProxy *evaluatedObject, NSDictionary *bindings)
                                              {
                                                  return [evaluatedObject localizedShortName].length > 0;
                                              }]];
    
    NSMutableArray* items = [NSMutableArray array];
    for (LSApplicationProxy* application in apps) {
        // System分类过滤隐藏app
        if (appType == $_LSSystemApplicationType && [self isAppHidden:application]) {
            continue;
        }
        
        UIImage *appIcon = [[UIImage alloc] init];
        if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
            appIcon = [UIImage _applicationIconImageForBundleIdentifier:application.applicationIdentifier format:0 scale:[UIScreen mainScreen].scale];
        }
        
        NSDictionary *item = @{
                               @"title": [application localizedShortName],
                               @"subtitle": application.applicationIdentifier,
                               @"icon": appIcon,
                               @"object": application,
                               };
        [items addObject:item];
    }
    
    return items;
}

- (BOOL)isAppHidden:(LSApplicationProxy *)application
{
    if (application.appTags.count > 0 && [application.appTags containsObject:@"hidden"]) {
        return YES;
    }
    
    NSArray *hideApps = [NSArray arrayWithObjects:
                         @"com.apple.webapp",
                         @"com.apple.webapp1",
                         @"com.apple.siri.parsec.HashtagImagesApp",
                         nil];
    if ([hideApps containsObject:application.applicationIdentifier]) {
        return YES;
    }

    return NO;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AppListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    NSDictionary *cellData = [self.tableData objectAtIndex:indexPath.row];
    
    cell.imageView.image = [cellData objectForKey:@"icon"];
    cell.textLabel.text = [cellData objectForKey:@"title"];
    cell.detailTextLabel.text = [cellData objectForKey:@"subtitle"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cellData = [self.tableData objectAtIndex:indexPath.row];
    
    FLEXObjectExplorerViewController *objectExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:[cellData objectForKey:@"object"]];
    [self.navigationController pushViewController:objectExplorer animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    BOOL canPerformAction = NO;
    
    if (action == @selector(copy:)) {
        canPerformAction = YES;
    }
    
    return canPerformAction;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        NSString *stringToCopy = @"";
        
        NSDictionary *cellData = [self.tableData objectAtIndex:indexPath.row];
        NSString *title = [cellData objectForKey:@"title"];
        if ([title length] > 0) {
            stringToCopy = [stringToCopy stringByAppendingString:title];
        }
        
        NSString *subtitle = [cellData objectForKey:@"subtitle"];
        if ([subtitle length] > 0) {
            if ([stringToCopy length] > 0) {
                stringToCopy = [stringToCopy stringByAppendingString:@"\n\n"];
            }
            stringToCopy = [stringToCopy stringByAppendingString:subtitle];
        }
        
        [[UIPasteboard generalPasteboard] setString:stringToCopy];
    }
}

@end
