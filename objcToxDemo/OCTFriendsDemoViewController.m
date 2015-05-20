//
//  OCTFriendsDemoViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 20/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "OCTFriendsDemoViewController.h"

static NSString *const kUITableViewCellIdentifier = @"kUITableViewCellIdentifier";

typedef NS_ENUM(NSUInteger, CellType) {
    CellTypeUserAddress,
    CellTypeUserPublicKey,
    CellTypeUserNospam,
    CellTypeUserStatus,
    CellTypeUserName,
    CellTypeUserStatusMessage,
};

@interface OCTFriendsDemoViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) OCTManager *manager;

@property (strong, nonatomic) NSMutableArray *data;

@end

@implementation OCTFriendsDemoViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    _data = [NSMutableArray arrayWithArray:@[
        [NSMutableArray arrayWithArray:@[
            @(CellTypeUserAddress),
            @(CellTypeUserPublicKey),
            @(CellTypeUserNospam),
            @(CellTypeUserStatus),
            @(CellTypeUserName),
            @(CellTypeUserStatusMessage),
        ]],
    ]];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Friends";

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kUITableViewCellIdentifier];
    [self.view addSubview:self.tableView];

    [self installConstraints];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark -  UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *array = self.data[section];

    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUITableViewCellIdentifier forIndexPath:indexPath];

    CellType type = [self cellTypeFromIndexPath:indexPath];

    switch(type) {
        case CellTypeUserAddress:
            [self configureUserAddressCell:cell];
            break;
        case CellTypeUserPublicKey:
            [self configureUserPublicKeyCell:cell];
            break;
        case CellTypeUserNospam:
            [self configureUserNospamCell:cell];
            break;
        case CellTypeUserStatus:
            [self configureUserStatusCell:cell];
            break;
        case CellTypeUserName:
            [self configureUserNameCell:cell];
            break;
        case CellTypeUserStatusMessage:
            [self configureUserStatusMessageCell:cell];
            break;
    }

    return cell;
}

#pragma mark -  Private

- (void)installConstraints
{
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (CellType)cellTypeFromIndexPath:(NSIndexPath *)path
{
    return [self.data[path.section][path.row] unsignedIntegerValue];
}

- (void)configureUserAddressCell:(UITableViewCell *)cell
{
    cell.textLabel.text = [NSString stringWithFormat:@"userAddress: %@", self.manager.user.userAddress];
}

- (void)configureUserPublicKeyCell:(UITableViewCell *)cell
{
    cell.textLabel.text = [NSString stringWithFormat:@"publicKey: %@", self.manager.user.publicKey];
}

- (void)configureUserNospamCell:(UITableViewCell *)cell
{
    cell.textLabel.text = [NSString stringWithFormat:@"nospam: %u", self.manager.user.nospam];
}

- (void)configureUserStatusCell:(UITableViewCell *)cell
{
    NSString *status = nil;
    switch(self.manager.user.userStatus) {
        case OCTToxUserStatusNone:
            status = @"None";
            break;
        case OCTToxUserStatusAway:
            status = @"Away";
            break;
        case OCTToxUserStatusBusy:
            status = @"Busy";
            break;
    }

    cell.textLabel.text = [NSString stringWithFormat:@"userStatus: %@", status];
}

- (void)configureUserNameCell:(UITableViewCell *)cell
{
    cell.textLabel.text = [NSString stringWithFormat:@"userName: %@", self.manager.user.userName];
}

- (void)configureUserStatusMessageCell:(UITableViewCell *)cell
{
    cell.textLabel.text = [NSString stringWithFormat:@"userStatusMessage: %@", self.manager.user.userStatusMessage];
}

@end
