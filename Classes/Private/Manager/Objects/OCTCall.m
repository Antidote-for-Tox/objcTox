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

@property (strong, nonatomic, readwrite) OCTChat *chatSession;
@property (strong, nonatomic, readwrite) NSArray *friends;
@property (nonatomic, assign, readwrite) OCTCallStatus status;

@end

@implementation OCTCall

- (instancetype)initWithChat:(OCTChat *)chat friend:(OCTFriend *)friend
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _chatSession = chat;
    _friends = @[friend];

    return self;
}

@end
