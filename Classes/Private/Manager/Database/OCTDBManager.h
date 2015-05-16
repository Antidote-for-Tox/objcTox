//
//  OCTDBManager.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import "OCTDBFriendRequest.h"
#import "OCTDBChat.h"

@interface OCTDBManager : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;

- (NSString *)path;

- (void)updateDBObjectInBlock:(void (^)())updateBlock;

#pragma mark -  Friend requests

- (RLMResults *)allFriendRequests;
- (void)addFriendRequest:(OCTDBFriendRequest *)friendRequest;
- (void)removeFriendRequestWithPublicKey:(NSString *)publicKey;

#pragma mark -  Friends

- (OCTDBFriend *)getOrCreateFriendWithFriendNumber:(NSInteger)friendNumber;

#pragma mark -  Chats

- (RLMResults *)allChats;
- (OCTDBChat *)getOrCreateChatWithFriendNumber:(NSInteger)friendNumber;
- (OCTDBChat *)chatWithUniqueIdentifier:(NSString *)uniqueIdentifier;
- (void)removeChatWithAllMessages:(OCTDBChat *)chat;

#pragma mark -  Messages

- (RLMResults *)allMessagesInChat:(OCTDBChat *)chat;

- (OCTDBMessageAbstract *)addMessageWithText:(NSString *)text
                                        type:(OCTToxMessageType)type
                                        chat:(OCTDBChat *)chat
                                      sender:(OCTDBFriend *)sender;

- (OCTDBMessageAbstract *)addMessageWithText:(NSString *)text
                                        type:(OCTToxMessageType)type
                                        chat:(OCTDBChat *)chat
                                      sender:(OCTDBFriend *)sender
                                   messageId:(int)messageId;

- (OCTDBMessageAbstract *)textMessageInChat:(OCTDBChat *)chat withMessageId:(int)messageId;

@end
