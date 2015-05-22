//
//  OCTFriendsViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendsViewController.h"

typedef NS_ENUM(NSUInteger, SectionType) {
    SectionTypeFriends = 0,
    SectionTypeFriendRequests,
    SectionTypeCount,
};

@interface OCTFriendsViewController ()

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

    self.title = @"Friends";

    return self;
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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

@end
