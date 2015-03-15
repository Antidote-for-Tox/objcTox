//
//  OCTSubmanagerFriends.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFriends.h"
#import "OCTFriendsContainer.h"

@interface OCTSubmanagerFriends()

@end

@implementation OCTSubmanagerFriends
@synthesize container = _container;

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _container = [OCTFriendsContainer new];

    return self;
}

@end
