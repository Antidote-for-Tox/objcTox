//
//  OCTSubmanagerChats.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerChats.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTTox.h"
#import "OCTRealmManager.h"
#import "RBQFetchRequest.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageText.h"
#import "OCTChat.h"

@interface OCTSubmanagerChats ()

@end

@implementation OCTSubmanagerChats
@synthesize dataSource = _dataSource;

#pragma mark -  Public

- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend
{
    return [[self.dataSource managerGetRealmManager] getOrCreateChatWithFriend:friend];
}

- (void)removeChatWithAllMessages:(OCTChat *)chat
{
    [[self.dataSource managerGetRealmManager] removeChatWithAllMessages:chat];
}

- (OCTMessageAbstract *)sendMessageToChat:(OCTChat *)chat
                                     text:(NSString *)text
                                     type:(OCTToxMessageType)type
                                    error:(NSError **)error
{
    NSParameterAssert(chat);
    NSParameterAssert(text);

    OCTTox *tox = [self.dataSource managerGetTox];
    OCTFriend *friend = [chat.friends firstObject];

    OCTToxMessageId messageId = [tox sendMessageWithFriendNumber:friend.friendNumber type:type message:text error:error];

    if (messageId == 0) {
        return nil;
    }

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    return [realmManager addMessageWithText:text type:type chat:chat sender:nil messageId:messageId];
}

- (BOOL)setIsTyping:(BOOL)isTyping inChat:(OCTChat *)chat error:(NSError **)error
{
    NSParameterAssert(chat);

    OCTFriend *friend = [chat.friends firstObject];
    OCTTox *tox = [self.dataSource managerGetTox];

    return [tox setUserIsTyping:isTyping forFriendNumber:friend.friendNumber error:error];
}

#pragma mark -  OCTToxDelegate

- (void)tox:(OCTTox *)tox friendMessage:(NSString *)message type:(OCTToxMessageType)type friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    OCTFriend *friend = [realmManager friendWithFriendNumber:friendNumber];
    OCTChat *chat = [realmManager getOrCreateChatWithFriend:friend];

    [realmManager addMessageWithText:message type:type chat:chat sender:friend messageId:0];
}

- (void)tox:(OCTTox *)tox messageDelivered:(OCTToxMessageId)messageId friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    OCTFriend *friend = [realmManager friendWithFriendNumber:friendNumber];
    OCTChat *chat = [realmManager getOrCreateChatWithFriend:friend];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chat == %@ AND messageText.messageId == %d",
                              chat, messageId];

    RBQFetchRequest *request = [realmManager fetchRequestForClass:[OCTMessageAbstract class] withPredicate:predicate];
    RLMResults *results = [request fetchObjects];

    OCTMessageAbstract *message = [results firstObject];

    if (! message) {
        return;
    }

    [realmManager updateObject:message withBlock:^(OCTMessageAbstract *theMessage) {
        theMessage.messageText.isDelivered = YES;
    }];
}

@end
