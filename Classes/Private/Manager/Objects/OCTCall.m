//
//  OCTCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall.h"
#import "OCTToxAVConstants.h"

@interface OCTCall ()

@end

@implementation OCTCall

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (! [object isKindOfClass:[OCTCall class]]) {
        return NO;
    }

    OCTCall *otherCall = object;

    return ([self.chat isEqual:otherCall.chat]);
}

- (NSUInteger)hash
{
    return [self.chat.uniqueIdentifier hash];
}

@end
