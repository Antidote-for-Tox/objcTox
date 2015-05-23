//
//  OCTFriendRequest.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendRequest.h"

@implementation OCTFriendRequest

#pragma mark -  Public

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCTFriendRequest with publicKey %@\nmessage %@", self.publicKey, self.message];
}

@end
