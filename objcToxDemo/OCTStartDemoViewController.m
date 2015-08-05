//
//  OCTStartDemoViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 20/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "OCTStartDemoViewController.h"
#import "OCTUserViewController.h"
#import "OCTFriendsViewController.h"
#import "OCTChatsViewController.h"
#import "AppDelegate.h"
#import "OCTManagerConfiguration.h"

#define NAVIGATION_WITH_CONTROLLER(class) \
    [[UINavigationController alloc] initWithRootViewController :[[class alloc] initWithManager:manager]]

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
            cell.textLabel.text = [NSString stringWithFormat:@"IPv6Enabled %u", self.configuration.options.IPv6Enabled];
            break;
        case RowUDPEnabled:
            cell.textLabel.text = [NSString stringWithFormat:@"UDPEnabled %u", self.configuration.options.UDPEnabled];
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
    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:self.configuration];

    UITabBarController *tabBar = [UITabBarController new];
    tabBar.viewControllers = @[
        NAVIGATION_WITH_CONTROLLER(OCTUserViewController),
        NAVIGATION_WITH_CONTROLLER(OCTFriendsViewController),
        NAVIGATION_WITH_CONTROLLER(OCTChatsViewController),
    ];

    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.window.rootViewController = tabBar;

    // [manager bootstrapFromHost:@"192.254.75.102"
    //                       port:33445
    //                  publicKey:@"951C88B7E75C867418ACDB5D273821372BB5BD652740BCDF623A4FA293E75D2F"
    //                      error:nil];

    // [manager bootstrapFromHost:@"178.62.125.224"
    //                       port:33445
    //                  publicKey:@"10B20C49ACBD968D7C80F2E8438F92EA51F189F4E70CFBBB2C2C8C799E97F03E"
    //                      error:nil];

    // [manager bootstrapFromHost:@"192.210.149.121"
    //                       port:33445
    //                  publicKey:@"F404ABAA1C99A9D37D61AB54898F56793E1DEF8BD46B1038B9D822E8460FAB67"
    //                      error:nil];
}

- (void)showActionSheetForRow:(Row)row
{
    __weak OCTStartDemoViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        switch (row) {
            case RowIPv6Enabled:
                {
                    [weakSelf addToSheet:sheet multiEditButtonWithOptions:@[ @"NO", @"YES" ] block:^(NSUInteger index) {
                    weakSelf.configuration.options.IPv6Enabled = (BOOL)index;
                }];
                    break;
                }
            case RowUDPEnabled:
                {
                    [weakSelf addToSheet:sheet multiEditButtonWithOptions:@[ @"NO", @"YES" ] block:^(NSUInteger index) {
                    weakSelf.configuration.options.UDPEnabled = (BOOL)index;
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
