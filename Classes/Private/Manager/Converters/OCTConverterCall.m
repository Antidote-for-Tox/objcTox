//
//  OCTConverterCall.m
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterCall.h"
#import "OCTConverterChat.h"
#import "OCTConverterFriend.h"
#import "OCTCall+Private.h"
#import "OCTDBCall.h"

@implementation OCTConverterCall

- (NSString *)objectClassName
{
    return NSStringFromClass([OCTCall class]);
}

- (NSString *)dbObjectClassName
{
    return NSStringFromClass([OCTDBCall class]);
}

- (id)objectFromRLMObject:(OCTDBCall *)dbCall
{
    NSParameterAssert(self.converterChat);
    OCTCall *call = [OCTCall new];

    OCTChat *chat = [self.converterChat objectFromRLMObject:dbCall.chat];

    call.chatSession = chat;
    call.friends = [chat.friends copy];

    return call;
}

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor
{
    return nil;
}

@end
