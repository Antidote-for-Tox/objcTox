//
//  OCTSubmanagerChat.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerChat.h"
#import "OCTSubmanagerChat+Private.h"
#import "OCTArray+Private.h"
#import "OCTConverterChat.h"
#import "OCTDBManager.h"

@interface OCTSubmanagerChat() <OCTConverterChatDelegate, OCTConverterFriendDataSource>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@end

@implementation OCTSubmanagerChat

#pragma mark -  Public

- (OCTArray *)allChats
{
    OCTConverterChat *converter = [OCTConverterChat new];
    converter.delegate = self;

    converter.converterFriend = [OCTConverterFriend new];
    converter.converterFriend.dataSource = self;

    converter.converterMessage = [OCTConverterMessage new];
    converter.converterMessage.converterFriend = converter.converterFriend;

    RLMResults *results = nil;

    return [[OCTArray alloc] initWithRLMResults:results converter:converter];
}

- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend
{
    return nil;
}

- (BOOL)setIsTyping:(BOOL)isTyping inChat:(OCTChat *)chat error:(NSError **)error
{
    return NO;
}

#pragma mark -  OCTConverterChatDelegate

- (void)converterChat:(OCTConverterChat *)converter updateDBChatWithBlock:(void (^)())block
{
    OCTDBManager *dbManager = [self.dataSource managerGetDBManager];

    [dbManager updateDBObjectInBlock:block];
}

#pragma mark -  OCTConverterFriendDataSource

- (OCTTox *)converterFriendGetTox:(OCTConverterFriend *)converterFriend
{
    return [self.dataSource managerGetTox];
}

@end
