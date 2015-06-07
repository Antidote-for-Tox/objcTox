//
//  OCTCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall.h"
#import "OCTAudioEngine.h"
#import "OCTToxAV.h"

@interface OCTCall ()

@end

@implementation OCTCall

- (instancetype)initWithChat:(OCTChat *)chat friend:(OCTFriend *)friend
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _chatSession = chat;
    _caller = friend;

    return self;
}

@end
