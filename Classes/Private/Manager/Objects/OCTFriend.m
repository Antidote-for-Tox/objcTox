//
//  OCTFriend.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 10.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriend.h"

@interface OCTFriend ()

@end

@implementation OCTFriend

#pragma mark -  Class methods

+ (NSArray *)requiredProperties
{
    NSMutableArray *properties = [NSMutableArray arrayWithArray:[super requiredProperties]];

    [properties addObject:NSStringFromSelector(@selector(nickname))];
    [properties addObject:NSStringFromSelector(@selector(publicKey))];

    return [properties copy];
}

#pragma mark -  Public

- (NSDate *)lastSeenOnline
{
    if (self.lastSeenOnlineInterval <= 0) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:self.lastSeenOnlineInterval];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCTFriend with friendNumber %u, name %@", self.friendNumber, self.name];
}

@end
