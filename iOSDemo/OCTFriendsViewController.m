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
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerChats.h"
#import "OCTSubmanagerFriends.h"

typedef NS_ENUM(NSUInteger, SectionType) {
    SectionTypeFriends = 0,
    SectionTypeFriendRequests,
    SectionTypeCount,
};

@interface OCTFriendsViewController ()

@property (strong, nonatomic) RLMResults<OCTFriend *> *friends;
@property (strong, nonatomic) RLMNotificationToken *friendsNotificationToken;
@property (strong, nonatomic) RLMResults<OCTFriendRequest *> *friendRequests;
@property (strong, nonatomic) RLMNotificationToken *friendRequestsNotificationToken;

@end

@implementation OCTFriendsViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _friends = [self.manager.objects objectsForType:OCTFetchRequestTypeFriend predicate:nil];
    _friendRequests = [self.manager.objects objectsForType:OCTFetchRequestTypeFriendRequest predicate:nil];

    self.title = @"Friends";

    return self;
}

- (void)dealloc
{
    [self.friendsNotificationToken stop];
    [self.friendRequestsNotificationToken stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.friendsNotificationToken = [self.friends addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        [weakSelf realmWasUpdated:changes sectionType:SectionTypeFriends error:error];
    }];

    self.friendRequestsNotificationToken = [self.friendRequests addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        [weakSelf realmWasUpdated:changes sectionType:SectionTypeFriendRequests error:error];
    }];

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

    switch (type) {
        case SectionTypeFriends:
            [self didSelectFriend:self.friends[indexPath.row]];
            break;
        case SectionTypeFriendRequests:
            [self didSelectFriendRequest:self.friendRequests[indexPath.row]];
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

    switch (type) {
        case SectionTypeFriends:
            return self.friends.count;
        case SectionTypeFriendRequests:
            return self.friendRequests.count;
        case SectionTypeCount:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SectionType type = section;

    switch (type) {
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

    switch (type) {
        case SectionTypeFriends:
            return [self friendCellAtIndexPath:indexPath];
        case SectionTypeFriendRequests:
            return [self friendRequestCellAtIndexPath:indexPath];
        case SectionTypeCount:
            return nil;
    }
}

#pragma mark -  Private

- (UITableViewCell *)friendCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    OCTFriend *friend = self.friends[indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"Friend\n"
                           @"friendNumber %u\n"
                           @"publicKey %@\n"
                           @"name %@\n"
                           @"nickname %@\n"
                           @"statusMessage %@\n"
                           @"status %@\n"
                           @"isConnected %d\n"
                           @"connectionStatus %@\n"
                           @"lastSeenOnline %@\n"
                           @"isTyping %d",
                           friend.friendNumber,
                           friend.publicKey,
                           friend.name,
                           friend.nickname,
                           friend.statusMessage,
                           [self stringFromUserStatus:friend.status],
                           friend.isConnected,
                           [self stringFromConnectionStatus:friend.connectionStatus],
                           friend.lastSeenOnline,
                           friend.isTyping];

    return cell;
}

- (UITableViewCell *)friendRequestCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    OCTFriendRequest *request = self.friendRequests[indexPath.row];

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

- (void)realmWasUpdated:(RLMCollectionChange *)changes sectionType:(SectionType)sectionType error:(NSError *)error
{
    if (error) {
        NSLog(@"Failed to open Realm on background worker: %@", error);
        return;
    }

    // Initial run of the query will pass nil for the change information
    if (! changes) {
        [self.tableView reloadData];
        return;
    }

    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[changes deletionsInSection:sectionType] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView insertRowsAtIndexPaths:[changes insertionsInSection:sectionType] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadRowsAtIndexPaths:[changes modificationsInSection:sectionType] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

@end
