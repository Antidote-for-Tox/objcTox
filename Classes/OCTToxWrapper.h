//
//  OCTToxWrapper.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 28.02.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "tox.h"

extern NSString *const kOCTToxWrapperErrorDomain;

/**
 * Length of address. Address is hex string, has following format:
 * [public_key (32 bytes, 64 characters)][nospam number (4 bytes, 8 characters)][checksum (2 bytes, 4 characters)]
 */
extern const NSUInteger kOCTToxAddressLength;

/**
 * Length of public key. It is hex string, 32 bytes, 64 characters.
 */
extern const NSUInteger kOCTToxPublicKeyLength;

/**
 * Errors for toxAddFriend method
 */
typedef NS_ENUM(NSUInteger, OCTToxWrapperAddFriendError) {
    // Unknown error
    OCTToxWrapperAddFriendErrorUnknown = 0,

    // The message is too long
    OCTToxWrapperAddFriendErrorMessageIsTooLong,

    // No message specified (message length must be >= 1)
    OCTToxWrapperAddFriendErrorNoMessage,

    // The message was send to own address
    OCTToxWrapperAddFriendErrorOwnAddress,

    // The friend request was already sent or already is a friend
    OCTToxWrapperAddFriendErrorAlreadySent,

    // Bad checksum in address
    OCTToxWrapperAddFriendErrorBadChecksum,

    // If the friend was already there but nospam was different
    // (the nospam for that friend was set to the new one).
    OCTToxWrapperAddFriendErrorSetNewNoSpam,

    // If increasing the friend list size fails
    OCTToxWrapperAddFriendErrorNoMem,
};

typedef NS_ENUM(NSUInteger, OCTToxWrapperConnectionStatus) {
    // The status is unknown (for example if there was a failure while getting it)
    OCTToxWrapperConnectionStatusUnknown,
    OCTToxWrapperConnectionStatusOffline,
    OCTToxWrapperConnectionStatusOnline,
};

typedef NS_ENUM(NSUInteger, OCTToxWrapperCheckLengthType) {
    OCTToxWrapperCheckLengthTypeFriendRequest,
    OCTToxWrapperCheckLengthTypeSendMessage,
    OCTToxWrapperCheckLengthTypeName,
    OCTToxWrapperCheckLengthTypeStatusMessage,
};

/**
 * Simple wrapper for all functions from tox.h file.
 */
@interface OCTToxWrapper : NSObject

#pragma mark -  Tox methods

/**
 * Get an tox address for specified Tox structure.
 *
 * @param tox Tox structure to work with.
 *
 * @return Address for Tox as a hex string. Address is kOCTToxAddressLength length and has following format:
 * [public_key (32 bytes, 64 characters)][nospam number (4 bytes, 8 characters)][checksum (2 bytes, 4 characters)]
 */
+ (NSString *)toxGetAddress:(const Tox *)tox;

/**
 * Add a friend.
 *
 * @param tox Tox structure to work with.
 * @param address Address of a friend to add. Must be exactry kOCTToxAddressLength length.
 * @param message Message that would be send with friend request. Minimum length - 1 byte.
 * @param error Error with OCTToxWrapperAddFriendError code.
 *
 * @return On success returns friend number.
 * @return On failure returns -1 and fills `error` parameter.
 *
 * @warning You can check maximum length of message with `+checkLengthOfString:withCheckType:` method with
 * OCTToxWrapperCheckLengthTypeFriendRequest type. If message will be too big it will be cropped to fit the length.
 */
+ (int32_t)toxAddFriend:(Tox *)tox address:(NSString *)address message:(NSString *)message error:(NSError **)error;

/**
 * Add a friend without sending friend request.
 *
 * @param tox Tox structure to work with.
 * @param publicKey Public key of a friend to add. Public key is hex string, must be exactry kOCTToxPublicKeyLength length.
 *
 * @return On success returns friend number.
 * @return On failure returns -1.
 */
+ (int32_t)toxAddFriendWithNoRequest:(Tox *)tox publicKey:(NSString *)publicKey;

/**
 * Get associated friend number from public key.
 *
 * @param tox Tox structure to work with.
 * @param publicKey Public key of a friend. Public key is hex string, must be exactry kOCTToxPublicKeyLength length.
 *
 * @return On success returns friend number.
 * @return If there is no such friend returns -1.
 */
+ (int32_t)toxGetFriendNumber:(const Tox *)tox publicKey:(NSString *)publicKey;

/**
 * Get public key from associated friend number.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Associated friend number
 *
 * @return Public key of a friend. Public key is hex string, must be exactry kOCTToxPublicKeyLength length.
 * @return If there is no such friend returns nil.
 */
+ (NSString *)toxGetPublicKey:(const Tox *)tox fromFriendNumber:(int32_t)friendNumber;

/**
 * Remove a friend
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to remove.
 *
 * @return YES on success, NO on failure.
 */
+ (BOOL)toxDeleteFriend:(Tox *)tox friendNumber:(int32_t)friendNumber;

/**
 * Get friend connection status.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to check status.
 *
 * @return Returns connection status or OCTToxWrapperAddFriendErrorUnknown in case of failure.
 */
+ (OCTToxWrapperConnectionStatus)toxGetFriendConnectionStatus:(const Tox *)tox friendNumber:(int32_t)friendNumber;

/**
 * Checks if there exists a friend with given friendNumber.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to check.
 *
 * @return YES if friend exists, NO otherwise.
 */
+ (BOOL)toxFriendExists:(const Tox *)tox friendNumber:(int32_t)friendNumber;

/**
 * Send a text chat message to an online friend.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to send a message.
 * @param message Message that would be send.
 *
 * @return The message id if packet was successfully put into the send queue, 0 if it was not.
 *
 * @warning You can check maximum length of message with `+checkLengthOfString:withCheckType:` method with
 * OCTToxWrapperCheckLengthTypeSendMessage type. If message will be too big it will be cropped to fit the length.
 */
+ (uint32_t)toxSendMessage:(Tox *)tox friendNumber:(int32_t)friendNumber message:(NSString *)message;

/**
 * Send an action to an online friend.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to send a action.
 * @param action Action that would be send.
 *
 * @return The message id if packet was successfully put into the send queue, 0 if it was not.
 *
 * @warning You can check maximum length of message with `+checkLengthOfString:withCheckType:` method with
 * OCTToxWrapperCheckLengthTypeSendMessage type. If message will be too big it will be cropped to fit the length.
 */
+ (uint32_t)toxSendAction:(Tox *)tox friendNumber:(int32_t)friendNumber action:(NSString *)action;

/**
 * Set our nickname.
 *
 * @param tox Tox structure to work with.
 * @param name Name to be set. Minimum length of name is 1 byte.
 *
 * @return YES on success, NO on failure.
 *
 * @warning You can check maximum length of message with `+checkLengthOfString:withCheckType:` method with
 * OCTToxWrapperCheckLengthTypeName type. If message will be too big it will be cropped to fit the length.
 */
+ (BOOL)toxSetName:(Tox *)tox name:(NSString *)name;

/**
 * Get your nickname.
 *
 * @param tox Tox structure to work with.
 *
 * @return Your nickname or nil in case of error.
 */
+ (NSString *)toxGetSelfName:(const Tox *)tox;

/**
 * Get name of friendNumber.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to get name.
 *
 * @return Name of friend or nil in case of error.
 */
+ (NSString *)toxGetFriendName:(const Tox *)tox friendNumber:(int32_t)friendNumber;

/**
 * Set our user status message.
 *
 * @param tox Tox structure to work with.
 * @param statusMessage Status message to be set.
 *
 * @return YES on success, NO on failure.
 *
 * @warning You can check maximum length of message with `+checkLengthOfString:withCheckType:` method with
 * OCTToxWrapperCheckLengthTypeStatusMessage type. If message will be too big it will be cropped to fit the length.
 */
+ (BOOL)toxSetStatusMessage:(Tox *)tox statusMessage:(NSString *)statusMessage;

#pragma mark -  Helper methods

/**
 * Checks length of string against maximum length  for specified type.
 *
 * @param string String to check.
 * @param type Type used to check string. Different types have different maximun length.
 *
 * @return YES, if string <= maximum length, NO otherwise.
 */
+ (BOOL)checkLengthOfString:(NSString *)string withCheckType:(OCTToxWrapperCheckLengthType)type;

/**
 * Crops string to fit maximum length for specified type.
 *
 * @param string String to crop.
 * @param type Type used to check string. Different types have different maximun length.
 *
 * @return The new cropped string.
 */
+ (NSString *)cropString:(NSString *)string toFitType:(OCTToxWrapperCheckLengthType)type;

@end
