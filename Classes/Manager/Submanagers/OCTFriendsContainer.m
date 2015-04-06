//
//  OCTFriendsContainer.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendsContainer.h"

@implementation OCTFriendsContainer
@synthesize friendsSort = _friendsSort;

#pragma mark -  OCTManagerFriendsProtocol

- (NSUInteger)friendsCount
{
    return 0;
}

- (OCTFriend *)friendAtIndex:(NSUInteger)index
{
    return nil;
}

#pragma mark -  Public

- (void)addFriend:(OCTFriend *)friend
{

}

- (void)updateFriendWithId:(OCTToxFriendNumber)friendNumber updateBlock:(void (^)(OCTFriend *friendToUpdate))updateBlock
{

}

- (void)removeFriend:(OCTFriend *)friend
{

}

@end
