//
//  OCTDBManager.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import "OCTDBFriendRequest.h"
#import "OCTDBChat.h"

@interface OCTDBManager : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;

- (NSString *)path;

- (void)updateDBObjectInBlock:(void (^)())updateBlock;

#pragma mark -  Friend requests

- (RLMResults *)allFriendRequests;
- (void)addFriendRequest:(OCTDBFriendRequest *)friendRequest;
- (void)removeFriendRequestWithPublicKey:(NSString *)publicKey;

#pragma mark -  Chats

- (RLMResults *)allChats;

@end
