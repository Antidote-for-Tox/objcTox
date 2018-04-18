// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Masonry/Masonry.h>

#import "OCTStartDemoViewController.h"
#import "OCTUserViewController.h"
#import "OCTFriendsViewController.h"
#import "OCTChatsViewController.h"
#import "OCTCallsViewController.h"
#import "OCTTabBarControllerViewController.h"
#import "AppDelegate.h"
#import "OCTManagerConfiguration.h"
#import "OCTManagerFactory.h"
#import "OCTSubmanagerBootstrap.h"

#define NAVIGATION_WITH_CONTROLLER(class) \
    [[UINavigationController alloc] initWithRootViewController:[[class alloc] initWithManager:manager]]

static NSString *const kLoginIdentifier = @"kLoginIdentifier";

typedef NS_ENUM(NSUInteger, Row) {
    RowBootstrap,
    RowIPv6Enabled,
    RowUDPEnabled,
    __RowCount,
};

@interface OCTStartDemoViewController ()

@property (strong, nonatomic) OCTManagerConfiguration *configuration;

@end

@implementation OCTStartDemoViewController

#pragma mark -  Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Start";
    self.configuration = [OCTManagerConfiguration defaultConfiguration];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    Row row = indexPath.row;

    switch (row) {
        case RowBootstrap:
            [self bootstrap];
            break;
        case RowIPv6Enabled:
        case RowUDPEnabled:
            [self showActionSheetForRow:row];
            break;
        case __RowCount:
            // nop
            break;
    }
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return __RowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    Row row = indexPath.row;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];

    switch (row) {
        case RowBootstrap:
            cell.textLabel.text = @"Bootstrap";
            cell.textLabel.textColor = [UIColor blueColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
            break;

        case RowIPv6Enabled:
            cell.textLabel.text = [NSString stringWithFormat:@"IPv6Enabled %u", self.configuration.options.ipv6Enabled];
            break;
        case RowUDPEnabled:
            cell.textLabel.text = [NSString stringWithFormat:@"UDPEnabled %u", self.configuration.options.udpEnabled];
            break;
        case __RowCount:
            // nop
            break;
    }

    return cell;
}

#pragma mark -  Private

- (void)bootstrap
{
    [OCTManagerFactory managerWithConfiguration:self.configuration encryptPassword:@"123" successBlock:^(id < OCTManager > manager) {
        OCTTabBarControllerViewController *tabBar = [OCTTabBarControllerViewController new];
        tabBar.viewControllers = @[
            NAVIGATION_WITH_CONTROLLER(OCTUserViewController),
            NAVIGATION_WITH_CONTROLLER(OCTFriendsViewController),
            NAVIGATION_WITH_CONTROLLER(OCTChatsViewController),
            NAVIGATION_WITH_CONTROLLER(OCTCallsViewController),
        ];

        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        delegate.window.rootViewController = tabBar;
        manager.calls.delegate = tabBar;

        [manager.bootstrap addPredefinedNodes];
        [manager.bootstrap bootstrap];
    } failureBlock:nil];
}

- (void)showActionSheetForRow:(Row)row
{
    __weak OCTStartDemoViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        switch (row) {
            case RowIPv6Enabled:
                {
                    [weakSelf addToSheet:sheet multiEditButtonWithOptions:@[ @"NO", @"YES" ] block:^(NSUInteger index) {
                    weakSelf.configuration.options.ipv6Enabled = (BOOL)index;
                }];
                    break;
                }
            case RowUDPEnabled:
                {
                    [weakSelf addToSheet:sheet multiEditButtonWithOptions:@[ @"NO", @"YES" ] block:^(NSUInteger index) {
                    weakSelf.configuration.options.udpEnabled = (BOOL)index;
                }];
                    break;
                }
            case RowBootstrap:
            case __RowCount:
                // nop
                break;
        }
    }];
}

@end
