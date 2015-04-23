//
//  OCTSubmanagerFriends.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriendsContainer.h"
#import "OCTFriendRequestContainer.h"

@interface OCTSubmanagerFriends : NSObject

/**
 * Container with all friends.
 */
@property (strong, nonatomic, readonly) OCTFriendsContainer *friendsContainer;

/**
 * Container with all friend requests.
 */
@property (strong, nonatomic, readonly) OCTFriendRequestContainer *friendRequestContainer;

/**
 * This adds friend to the list.
 * address and message are required.
 */
- (BOOL)sendFriendRequestToAddress:(NSString *)address message:(NSString *)message error:(NSError **)error;
- (BOOL)approveFriendRequest:(OCTFriendRequest *)friendRequest error:(NSError **)error;
- (BOOL)removeFriendRequest:(OCTFriendRequest *)friendRequest;

- (BOOL)removeFriend:(OCTFriend *)friend error:(NSError **)error;

@end
