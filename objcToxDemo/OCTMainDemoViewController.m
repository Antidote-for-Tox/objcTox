//
//  OCTMainDemoViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 20/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <Masonry/Masonry.h>

#import "OCTMainDemoViewController.h"

static NSString *const kUITableViewCellIdentifier = @"kUITableViewCellIdentifier";

typedef NS_ENUM(NSUInteger, SectionType) {
    SectionTypeUser = 0,
    SectionTypeFriends,
    SectionTypeFriendRequests,
    SectionTypeCount,
};

typedef NS_ENUM(NSUInteger, RowUser) {
    RowUserUserAddress,
    RowUserUserPublicKey,
    RowUserUserNospam,
    RowUserUserStatus,
    RowUserUserName,
    RowUserUserStatusMessage,
};

@interface OCTMainDemoViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) OCTManager *manager;

@property (strong, nonatomic) NSArray *userData;
@property (strong, nonatomic) OCTFriendsContainer *friendsContainer;
@property (strong, nonatomic) OCTArray *allFriendRequests;

@end

@implementation OCTMainDemoViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    _userData = @[
        @(RowUserUserAddress),
        @(RowUserUserPublicKey),
        @(RowUserUserNospam),
        @(RowUserUserStatus),
        @(RowUserUserName),
        @(RowUserUserStatusMessage),
    ];

    _friendsContainer = self.manager.friends.friendsContainer;
    _allFriendRequests = self.manager.friends.allFriendRequests;

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Friends";

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kUITableViewCellIdentifier];
    [self.view addSubview:self.tableView];

    [self installConstraints];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    SectionType type = indexPath.section;

    switch(type) {
        case SectionTypeUser:
            [self didSelectUserRow:indexPath.row];
            break;
        case SectionTypeFriends:
        case SectionTypeFriendRequests:
        case SectionTypeCount:
            // nop
            break;
    }
}

#pragma mark -  UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionTypeCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    SectionType type = section;

    switch(type) {
        case SectionTypeUser:
            return self.userData.count;
        case SectionTypeFriends:
            return self.friendsContainer.friendsCount;
        case SectionTypeFriendRequests:
            return self.allFriendRequests.count;
        case SectionTypeCount:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SectionType type = section;

    switch(type) {
        case SectionTypeUser:
            return @"User";
        case SectionTypeFriends:
            return @"Friends";
        case SectionTypeFriendRequests:
            return @"FriendRequests";
        case SectionTypeCount:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SectionType type = indexPath.section;

    switch(type) {
        case SectionTypeUser:
            return [self userCellAtIndexPath:indexPath];
        case SectionTypeFriends:
           return [self friendCellAtIndexPath:indexPath];
        case SectionTypeFriendRequests:
           return [self friendRequestCellAtIndexPath:indexPath];
        case SectionTypeCount:
            return nil;
    }
}

#pragma mark -  Private

- (void)installConstraints
{
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kUITableViewCellIdentifier
                                                                 forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;

    return cell;
}

- (UITableViewCell *)userCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    RowUser row = indexPath.row;

    switch(row) {
        case RowUserUserAddress:
            cell.textLabel.text = [NSString stringWithFormat:@"userAddress: %@", self.manager.user.userAddress];
            break;
        case RowUserUserPublicKey:
            cell.textLabel.text = [NSString stringWithFormat:@"publicKey: %@", self.manager.user.publicKey];
            break;
        case RowUserUserNospam:
            cell.textLabel.text = [NSString stringWithFormat:@"nospam: %u", self.manager.user.nospam];
            break;
        case RowUserUserStatus:
            cell.textLabel.text = [NSString stringWithFormat:@"userStatus: %@",
                                      [self stringFromUserStatus:self.manager.user.userStatus]];
            break;
        case RowUserUserName:
            cell.textLabel.text = [NSString stringWithFormat:@"userName: %@", self.manager.user.userName];
            break;
        case RowUserUserStatusMessage:
            cell.textLabel.text = [NSString stringWithFormat:@"userStatusMessage: %@", self.manager.user.userStatusMessage];
            break;
    }

    return cell;
}

- (UITableViewCell *)friendCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTFriend *friend = [self.friendsContainer friendAtIndex:indexPath.row];
    cell.textLabel.text = friend.name ?: friend.publicKey;
    return cell;
}

- (UITableViewCell *)friendRequestCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTFriendRequest *request = [self.allFriendRequests objectAtIndex:indexPath.row];
    cell.textLabel.text = request.publicKey;
    return cell;
}

- (void)didSelectUserRow:(RowUser)row
{
    __weak OCTMainDemoViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        switch(row) {
            case RowUserUserAddress:
                [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.userAddress];
                break;
            case RowUserUserPublicKey:
                [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.publicKey];
                break;
            case RowUserUserNospam:
            {
                [weakSelf addToSheet:sheet copyButtonWithValue:@(weakSelf.manager.user.nospam)];
                [weakSelf addToSheet:sheet textEditButtonWithValue:@(weakSelf.manager.user.nospam) block:^(NSString *string) {
                    weakSelf.manager.user.nospam = (OCTToxNoSpam)[string integerValue];
                }];
                break;
            }
            case RowUserUserStatus:
            {
                [weakSelf addToSheet:sheet multiEditButtonWithOptions:@[
                    [weakSelf stringFromUserStatus:0],
                    [weakSelf stringFromUserStatus:1],
                    [weakSelf stringFromUserStatus:2],

                ] block:^(NSUInteger index) {
                    weakSelf.manager.user.userStatus = index;
                }];
                break;
            }
            case RowUserUserName:
            {
                [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.userName];
                [weakSelf addToSheet:sheet textEditButtonWithValue:weakSelf.manager.user.userName block:^(NSString *string) {
                    NSError *error;
                    [weakSelf.manager.user setUserName:string error:&error];
                    [self maybeShowError:error];
                }];
                break;
            }
            case RowUserUserStatusMessage:
            {
                [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.userStatusMessage];
                [weakSelf addToSheet:sheet textEditButtonWithValue:weakSelf.manager.user.userStatusMessage block:^(NSString *string) {
                    NSError *error;
                    [weakSelf.manager.user setUserStatusMessage:string error:&error];
                    [self maybeShowError:error];
                }];
                break;
            }
        }
    }];
}

- (void)showActionSheet:(void (^)(UIActionSheet *sheet))block
{
    if (! block) {
        return;
    }

    UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:@"Select action"];
    [sheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

    block(sheet);

    [sheet showInView:self.view];
}

- (void)addToSheet:(UIActionSheet *)sheet copyButtonWithValue:(id)value
{
    [sheet bk_addButtonWithTitle:@"Copy" handler:^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [self stringFromValue:value];
    }];
}

- (void)addToSheet:(UIActionSheet *)sheet textEditButtonWithValue:(id)value block:(void (^)(NSString *string))block
{
    NSParameterAssert(block);

    __weak OCTMainDemoViewController *weakSelf = self;

    [sheet bk_addButtonWithTitle:@"Edit" handler:^{
        UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"" message:nil];

        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] setText:[self stringFromValue:value]];

        [alert bk_addButtonWithTitle:@"OK" handler:^{
            block([alert textFieldAtIndex:0].text);

            [weakSelf.tableView reloadData];
        }];

        [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

        [alert show];
    }];
}

- (void)         addToSheet:(UIActionSheet *)sheet
 multiEditButtonWithOptions:(NSArray *)options
                      block:(void (^)(NSUInteger index))block
{
    NSParameterAssert(block);

    __weak OCTMainDemoViewController *weakSelf = self;

    [sheet bk_addButtonWithTitle:@"Edit" handler:^{
        UIActionSheet *editSheet = [UIActionSheet bk_actionSheetWithTitle:@"Select action"];

        for (NSUInteger index = 0; index < options.count; index++) {
            [editSheet bk_addButtonWithTitle:options[index] handler:^{
                block(index);
                [weakSelf.tableView reloadData];
            }];
        }

        [editSheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [editSheet showInView:weakSelf.view];
    }];
}
- (NSString *)stringFromValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }

    if ([value isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@", value];
    }

    return nil;
}

- (NSString *)stringFromUserStatus:(OCTToxUserStatus)status
{
    switch(status) {
        case OCTToxUserStatusNone:
            return @"None";
        case OCTToxUserStatusAway:
            return @"Away";
        case OCTToxUserStatusBusy:
            return @"Busy";
    }
}

- (void)maybeShowError:(NSError *)error
{
    if (! error) {
        return;
    }

    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:error.localizedDescription
                                                    message:error.localizedFailureReason];
    [alert bk_setCancelButtonWithTitle:@"OK" handler:nil];
    [alert show];
}

@end
