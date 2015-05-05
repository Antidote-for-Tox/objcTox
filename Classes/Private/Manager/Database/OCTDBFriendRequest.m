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
    NSParameterAssert(friendRequest);

    OCTDBFriendRequest *db = [OCTDBFriendRequest new];
    db.publicKey = friendRequest.publicKey;
    db.message = friendRequest.message;

    return db;
}

@end
