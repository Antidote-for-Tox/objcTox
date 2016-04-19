//
//  OCTSubmanagerChats.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"

@class OCTChat;
@class OCTFriend;
@class OCTMessageAbstract;

@interface OCTSubmanagerChats : NSObject

/**
 * Searches for a chat with specific friend. If chat is not found creates one and returns it.
 *
 * @param friend Friend to get/create chat with.
 *
 * @return Chat with specific friend.
 */
- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend;

/**
 * Removes given messages.
 *
 * @param messages Array with messages to remove.
 *
 * @warning Destructive operation! There is no way to restore messages after removal.
 */
- (void)removeMessages:(NSArray<OCTMessageAbstract *> *)messages;

/**
 * Removes chat and all appropriate messages.
 *
 * @param chat Chat to remove.
 *
 * @warning Destructive operation! There is no way to restore chat or messages after removal.
 */
- (void)removeChatWithAllMessages:(OCTChat *)chat;

/**
 * Send text message to specific chat
 *
 * @param chat Chat send message to.
 * @param text Text to send.
 * @param type Type of message to send.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendSendMessage for all error codes.
 *
 * @return Returns message, or nil if there was an error.
 */
- (OCTMessageAbstract *)sendMessageToChat:(OCTChat *)chat
                                     text:(NSString *)text
                                     type:(OCTToxMessageType)type
                                    error:(NSError **)error;

/**
 * Set our typing status for a chat. You are responsible for turning it on or off.
 *
 * @param isTyping Status showing whether user is typing or not.
 * @param chat Chat to set typing status.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorSetTyping for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)setIsTyping:(BOOL)isTyping inChat:(OCTChat *)chat error:(NSError **)error;

@end
