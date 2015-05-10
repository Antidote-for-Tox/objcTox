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

@property (strong, nonatomic) OCTConverterChat *converterChat;

@end

@implementation OCTSubmanagerChat

#pragma mark -  Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _converterChat = [OCTConverterChat new];
    _converterChat.delegate = self;

    _converterChat.converterFriend = [OCTConverterFriend new];
    _converterChat.converterFriend.dataSource = self;

    _converterChat.converterMessage = [OCTConverterMessage new];
    _converterChat.converterMessage.converterFriend = _converterChat.converterFriend;

    return self;
}

#pragma mark -  Public

- (OCTArray *)allChats
{
    RLMResults *results = [[self.dataSource managerGetDBManager] allChats];

    return [[OCTArray alloc] initWithRLMResults:results converter:self.converterChat];
}

- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend
{
    OCTDBChat *db = [[self.dataSource managerGetDBManager] getOrCreateChatWithFriendNumber:friend.friendNumber];

    return (OCTChat *)[self.converterChat objectFromRLMObject:db];
}

- (BOOL)setIsTyping:(BOOL)isTyping inChat:(OCTChat *)chat error:(NSError **)error
{
    OCTFriend *friend = [chat.friends lastObject];
    OCTTox *tox = [self.dataSource managerGetTox];

    return [tox setUserIsTyping:isTyping forFriendNumber:friend.friendNumber error:error];
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
