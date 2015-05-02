//
//  OCTDBManager.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriendRequest.h"

@interface OCTDBManager : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;

- (NSString *)path;

- (void)updateDBObjectInBlock:(void (^)())updateBlock;

#pragma mark -  Friend requests

- (NSArray *)friendRequests;
- (void)addFriendRequest:(OCTFriendRequest *)friendRequest;
- (void)removeFriendRequest:(OCTFriendRequest *)friendRequest;

@end
