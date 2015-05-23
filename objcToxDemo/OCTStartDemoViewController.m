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

#define NAVIGATION_WITH_CONTROLLER(class) \
    [[UINavigationController alloc] initWithRootViewController:[[class alloc] initWithManager:manager]]

static NSString *const kLoginIdentifier = @"kLoginIdentifier";

@interface OCTStartDemoViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation OCTStartDemoViewController

#pragma mark -  Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Start";

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kLoginIdentifier];
    [self.view addSubview:self.tableView];

    [self installConstraints];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration];

    [self bootstrap:manager];

    UITabBarController *tabBar = [UITabBarController new];
    tabBar.viewControllers = @[
        NAVIGATION_WITH_CONTROLLER(OCTUserViewController),
        NAVIGATION_WITH_CONTROLLER(OCTFriendsViewController),
        NAVIGATION_WITH_CONTROLLER(OCTChatsViewController),
    ];

    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.window.rootViewController = tabBar;
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLoginIdentifier forIndexPath:indexPath];
    cell.textLabel.text = @"Bootstrap";
    cell.textLabel.textColor = [UIColor blueColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];

    return cell;
}

#pragma mark -  Private

- (void)installConstraints
{
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)bootstrap:(OCTManager *)manager
{
    [manager bootstrapFromHost:@"192.254.75.102"
                          port:33445
                     publicKey:@"951C88B7E75C867418ACDB5D273821372BB5BD652740BCDF623A4FA293E75D2F"
                         error:nil];

    [manager bootstrapFromHost:@"178.62.125.224"
                          port:33445
                     publicKey:@"10B20C49ACBD968D7C80F2E8438F92EA51F189F4E70CFBBB2C2C8C799E97F03E"
                         error:nil];

    [manager bootstrapFromHost:@"192.210.149.121 "
                          port:33445
                     publicKey:@"F404ABAA1C99A9D37D61AB54898F56793E1DEF8BD46B1038B9D822E8460FAB67"
                         error:nil];
}

@end
