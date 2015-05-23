//
//  OCTFriendsViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>

#import "OCTFriendsViewController.h"

typedef NS_ENUM(NSUInteger, SectionType) {
    SectionTypeFriends = 0,
    SectionTypeFriendRequests,
    SectionTypeCount,
};

@interface OCTFriendsViewController () <OCTArrayDelegate>

@property (strong, nonatomic) OCTFriendsContainer *friendsContainer;
@property (strong, nonatomic) OCTArray *allFriendRequests;

@end

@implementation OCTFriendsViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _friendsContainer = self.manager.friends.friendsContainer;
    _allFriendRequests = self.manager.friends.allFriendRequests;
    _allFriendRequests.delegate = self;

    self.title = @"Friends";

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(friendUpdateNotification)
                                                 name:kOCTFriendsContainerUpdateNotification
                                               object:nil];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak OCTFriendsViewController *weakSelf = self;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id handler) {
            [weakSelf sendFriendRequest];
        }];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    SectionType type = indexPath.section;

    switch(type) {
        case SectionTypeFriends:
            [self didSelectFriend:[self.friendsContainer friendAtIndex:indexPath.row]];
            break;
        case SectionTypeFriendRequests:
            [self didSelectFriendRequest:self.allFriendRequests[indexPath.row]];
            break;
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
        case SectionTypeFriends:
           return [self friendCellAtIndexPath:indexPath];
        case SectionTypeFriendRequests:
           return [self friendRequestCellAtIndexPath:indexPath];
        case SectionTypeCount:
            return nil;
    }
}

#pragma mark -  OCTArrayDelegate

- (void)OCTArrayWasUpdated:(OCTArray *)array
{
    [self.tableView reloadData];
}

#pragma mark -  NSNotification

- (void)friendUpdateNotification
{
    [self.tableView reloadData];
}

#pragma mark -  Private

- (UITableViewCell *)friendCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTFriend *friend = [self.friendsContainer friendAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Friend\n"
        @"friendNumber %u\n"
        @"publicKey %@\n"
        @"name %@\n"
        @"statusMessage %@\n"
        @"status %@\n"
        @"connectionStatus %@\n"
        @"lastSeenOnline %@\n"
        @"isTyping %d",
        friend.friendNumber,
        friend.publicKey,
        friend.name,
        friend.statusMessage,
        [self stringFromUserStatus:friend.status],
        [self stringFromConnectionStatus:friend.connectionStatus],
        friend.lastSeenOnline,
        friend.isTyping];

    return cell;
}

- (UITableViewCell *)friendRequestCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTFriendRequest *request = [self.allFriendRequests objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Friend request\n"
        @"publicKey %@\n"
        @"message %@\n",
        request.publicKey, request.message];

    return cell;
}

- (void)didSelectFriend:(OCTFriend *)friend
{
    __weak OCTFriendsViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Create chat" handler:^{
            [weakSelf.manager.chats getOrCreateChatWithFriend:friend];
        }];

        [sheet bk_addButtonWithTitle:@"Remove" handler:^{
            [weakSelf.manager.friends removeFriend:friend error:nil];
        }];
    }];
}

- (void)didSelectFriendRequest:(OCTFriendRequest *)request
{
    __weak OCTFriendsViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Add" handler:^{
            [weakSelf.manager.friends approveFriendRequest:request error:nil];
        }];

        [sheet bk_addButtonWithTitle:@"Remove" handler:^{
            [weakSelf.manager.friends removeFriendRequest:request];
        }];
    }];
}

- (void)sendFriendRequest
{
    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Send friend request" message:nil];

    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    UITextField *addressField = [alert textFieldAtIndex:0];
    addressField.placeholder = @"Address";
    UITextField *messageField = [alert textFieldAtIndex:1];
    messageField.placeholder = @"Message";
    messageField.secureTextEntry = NO;

    __weak OCTFriendsViewController *weakSelf = self;
    [alert bk_addButtonWithTitle:@"OK" handler:^{
       [weakSelf.manager.friends sendFriendRequestToAddress:addressField.text message:messageField.text error:nil];
       [weakSelf.tableView reloadData];
    }];

    [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

    [alert show];
}

@end
