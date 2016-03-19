//
//  OCTFriendRequest.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendRequest.h"

@implementation OCTFriendRequest

#pragma mark -  Class methods

+ (NSArray *)requiredProperties
{
    NSMutableArray *properties = [NSMutableArray arrayWithArray:[super requiredProperties]];

    [properties addObject:NSStringFromSelector(@selector(publicKey))];

    return [properties copy];
}

#pragma mark -  Public

- (NSDate *)date
{
    return [NSDate dateWithTimeIntervalSince1970:self.dateInterval];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCTFriendRequest with publicKey %@...\nmessage length %lu",
            [self.publicKey substringToIndex:5], (unsigned long)self.message.length];
}

@end
