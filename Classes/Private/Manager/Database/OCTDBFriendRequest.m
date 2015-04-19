//
//  OCTDBFriendRequest.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBFriendRequest.h"

@implementation OCTDBFriendRequest

#pragma mark -  Class methods

+ (NSString *)primaryKey
{
    return @"publicKey";
}

+ (instancetype)createFromFriendRequest:(OCTFriendRequest *)friendRequest
{
    NSParameterAssert(friendRequest.publicKey);

    OCTDBFriendRequest *db = [OCTDBFriendRequest new];
    db.publicKey = friendRequest.publicKey;
    db.message = friendRequest.message;

    return db;
}

#pragma mark -  Methods

- (OCTFriendRequest *)friendRequest
{
    OCTFriendRequest *friendRequest = [OCTFriendRequest new];
    friendRequest.publicKey = self.publicKey;
    friendRequest.message = self.message;

    return friendRequest;
}

@end
