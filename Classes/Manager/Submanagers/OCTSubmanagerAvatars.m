//
//  OCTSubmanagerAvatars.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerAvatars.h"

@interface OCTSubmanagerAvatars()

@end

@implementation OCTSubmanagerAvatars

#pragma mark -  OCTManagerAvatarsProtocol

- (void)setAvatar:(UIImage *)avatar
{
    // TODO
}

- (UIImage *)avatar
{
    // TODO
    return nil;
}

- (BOOL)hasAvatar
{
    // TODO
    return NO;
}

#pragma mark -  OCTToxDelegate

- (void)tox:(OCTTox *)tox friendAvatarHashUpdate:(NSData *)hash friendNumber:(int32_t)friendNumber
{
    // TODO
}

- (void)tox:(OCTTox *)tox friendAvatarUpdate:(NSData *)avatar hash:(NSData *)hash friendNumber:(int32_t)friendNumber
{
    // TODO
}

@end
