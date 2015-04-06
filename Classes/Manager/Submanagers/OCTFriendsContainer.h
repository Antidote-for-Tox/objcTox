//
//  OCTFriendsContainer.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriendsContainerProtocol.h"
#import "OCTSettingsStorageProtocol.h"

@protocol OCTFriendsContainerDataSource <NSObject>
- (id<OCTSettingsStorageProtocol>)friendsContainerGetSettingsStorage;
@end

@interface OCTFriendsContainer : NSObject <OCTFriendsContainerProtocol>

@property (weak, nonatomic) id<OCTFriendsContainerDataSource> dataSource;

- (instancetype)initWithFriendsArray:(NSArray *)friends;

- (void)configure;

- (void)addFriend:(OCTFriend *)friend;
- (void)updateFriendWithId:(OCTToxFriendNumber)friendNumber updateBlock:(void (^)(OCTFriend *friendToUpdate))updateBlock;
- (void)removeFriend:(OCTFriend *)friend;

@end
