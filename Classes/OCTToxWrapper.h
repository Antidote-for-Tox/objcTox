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
 * Length of address. Address has following format:
 * [public_key (32 bytes, 64 characters)][nospam number (4 bytes, 8 characters)][checksum (2 bytes, 4 characters)]
 */
extern const NSUInteger kOCTToxAddressLength;

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
 * @return On success returns friends number.
 * @return On failure returns -1 and fills `error` parameter.
 *
 * @warning You can check maximum length of message with `+checkFriendRequestMessageLength:` method. If message
 * will be too big it will be cropped to fit the length.
 */
+ (int32_t)toxAddFriend:(Tox *)tox address:(NSString *)address message:(NSString *)message error:(NSError **)error;

#pragma mark -  Helper methods

/**
 * Checks length of message for friend request against maximum length.
 *
 * @return YES, if message <= maximum length.
 * @return NO,  if message is too big. You can crop it with method `+cropFriendRequestMessageToFit:`.
 */
+ (BOOL)checkFriendRequestMessageLength:(NSString *)message;

/**
 * Crops message for friend request to fit maximum length.
 *
 * @return The new cropped message.
 */
+ (NSString *)cropFriendRequestMessageToFit:(NSString *)message;

@end
