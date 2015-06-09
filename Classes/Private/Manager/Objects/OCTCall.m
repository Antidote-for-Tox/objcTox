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

@property (strong, nonatomic, readwrite) OCTChat *chat;
@property (nonatomic, assign, readwrite) OCTCallStatus status;

@end

@implementation OCTCall

- (instancetype)initCallWithChat:(OCTChat *)chat
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _chat = chat;

    return self;
}

@end
