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
- (void)tox:(OCTTox *)tox friendMessage:(NSString *)message friendNumber:(int32_t)friendNumber;

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
 * TODO: Add info about delegate
 */
- (void)tox:(OCTTox *)tox fileSendControlWithFriendNumber:(int32_t)friendNumber sendReceive:(uint8_t)sendReceive fileNumber:(uint8_t)fileNumber controlType:(uint8_t)controlType data:(const uint8_t *)data length:(uint16_t)length;

/**
 * TODO: Add info about delegate
 */
- (void)tox:(OCTTox *)tox fileSendDataWithFriendNumber:(int32_t)friendNumber fileNumber:(uint8_t)fileNumber data:(const uint8_t *)data length:(uint16_t)length;

@end
