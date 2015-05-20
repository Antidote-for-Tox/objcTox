//
//  OCTStartDemoViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 20/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "OCTStartDemoViewController.h"
#import "OCTMainDemoViewController.h"

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

    OCTMainDemoViewController *vc = [[OCTMainDemoViewController alloc] initWithManager:manager];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLoginIdentifier forIndexPath:indexPath];
    cell.textLabel.text = @"Login";
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

@end
