//
//  OCTFriendsContainer.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriendsContainerProtocol.h"

@interface OCTFriendsContainer : NSObject <OCTFriendsContainerProtocol>

- (void)addFriend:(OCTFriend *)friend;
- (void)updateFriendWithId:(int32_t)id updateBlock:(void (^)(OCTFriend *friendToUpdate))updateBlock;
- (void)removeFriend:(OCTFriend *)friend;

@end
