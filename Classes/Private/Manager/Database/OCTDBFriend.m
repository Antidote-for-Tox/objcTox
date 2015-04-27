//
//  OCTDBFriend.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 27.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBFriend.h"
#import "RLMRealm.h"

@implementation OCTDBFriend

+ (NSString *)primaryKey
{
    return @"friendNumber";
}

+ (instancetype)findOrCreateFriendInRealm:(RLMRealm *)realm withFriendNumber:(NSInteger)friendNumber
{
    OCTDBFriend *friend = [OCTDBFriend new];
    friend.friendNumber = friendNumber;

    [realm beginWriteTransaction];
    friend = [self createOrUpdateInRealm:realm withObject:friend];
    [realm commitWriteTransaction];

    return friend;
}

@end
