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

#pragma mark -  Public

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCTFriend with friendNumber %u, name %@", self.friendNumber, self.name];
}

@end
