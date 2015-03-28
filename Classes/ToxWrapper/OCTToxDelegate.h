//
//  OCTToxDelegate.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 03.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"

@class OCTTox;
@protocol OCTToxDelegate <NSObject>

@optional

/**
 * User connection status changed.
 *
 * @param connectionStatus New connection status of the user.
 */
- (void)tox:(OCTTox *)tox connectionStatus:(OCTToxConnectionStatus)connectionStatus;

/**
 * Received friend request from a new friend.
 *
 * @param message Message sent with request>
 * @param publicKey New friend public key.
 */
- (void)tox:(OCTTox *)tox friendRequestWithMessage:(NSString *)message publicKey:(NSString *)publicKey;

/**
 * Message received from a friend.
 *
 * @param message Received message.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendMessage:(NSString *)message type:(OCTToxMessageType)type friendNumber:(int32_t)friendNumber;

/**
 * Action received from a friend.
 *
 * @param action Received action.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendAction:(NSString *)action friendNumber:(int32_t)friendNumber;

/**
 * Friend's name was updated.
 *
 * @param name Updated name.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendNameUpdate:(NSString *)name friendNumber:(int32_t)friendNumber;

/**
 * Friend's status message was updated.
 *
 * @param statusMessage Updated status message.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendStatusMessageUpdate:(NSString *)statusMessage friendNumber:(int32_t)friendNumber;

/**
 * Friend's status was updated.
 *
 * @param status Updated status.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendStatusUpdate:(OCTToxUserStatus)status friendNumber:(int32_t)friendNumber;

/**
 * Friend's isTyping was updated
 *
 * @param isTyping Updated typing status.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendIsTypingUpdate:(BOOL)isTyping friendNumber:(int32_t)friendNumber;

/**
 * Message that was previously sent by us has been delivered to a friend.
 *
 * @param messageId Id of message. You could get in in sendMessage method.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox messageDelivered:(uint32_t)messageId friendNumber:(int32_t)friendNumber;

/**
 * Friend's connection status changed.
 *
 * @param status Updated status.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendConnectionStatusChanged:(OCTToxConnectionStatus)status friendNumber:(int32_t)friendNumber;

/**
 * Friend's avatar hash was updated.
 *
 * @param hash Updated hash.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendAvatarHashUpdate:(NSData *)hash friendNumber:(int32_t)friendNumber;

/**
 * Friend's avatar was updated.
 *
 * @param avatar Updated avatar. Can be used to create UIImage from it.
 * @param hash Updated hash.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)tox:(OCTTox *)tox friendAvatarUpdate:(NSData *)avatar hash:(NSData *)hash friendNumber:(int32_t)friendNumber;

/**
 * Set the callback for file to be received from friend
 *
 * @param fileName Name of file to be received from friend
 * @param friendNumber Friend number of appropriate friend.
 * @param fileSize Size of file
 */
- (void)tox:(OCTTox *)tox fileSendRequestWithFileName:(NSString *)fileName friendNumber:(int32_t)friendNumber fileSize:(uint64_t)fileSize;

/**
 * Set the callback for accepting or refusig connection while sending or receiving file
 *
 * @param friendNumber Friend number to send/receive file
 * @param sendOrReceive is OCTToxFileControlTypeSend if we want the control packet to target a file we are currently sending,
 * OCTToxFileControlReceive if it targets a file we are currently receiving.
 * @param fileNumber Number of file to be sent/received
 * @param controlType Type of file control
 * @param data Pointer on data
 */
- (void)tox:(OCTTox *)tox fileSendControlWithFriendNumber:(int32_t)friendNumber sendOrReceive:(OCTToxFileControlType)sendOrReceive fileNumber:(uint8_t)fileNumber controlType:(OCTToxFileControl)controlType data:(NSData *)data;

/**
 * Set the callback for sending file data 
 *
 * @param friendNumber Friend number to send/receive file
 * @param fileNumber Number of file to be sent/received
 * @param data Pointer on data
 */
- (void)tox:(OCTTox *)tox fileSendDataWithFriendNumber:(int32_t)friendNumber fileNumber:(uint8_t)fileNumber data:(NSData *)data;

@end
