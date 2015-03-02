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

typedef NS_ENUM(NSUInteger, OCTToxWrapperProxyType) {
    OCTToxWrapperProxyTypeNone,
    OCTToxWrapperProxyTypeSocks5,
    OCTToxWrapperProxyTypeHTTP,
};

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

typedef NS_ENUM(NSUInteger, OCTToxWrapperDataLengthType) {
    OCTToxWrapperDataLengthTypeAvatar,
};

typedef NS_ENUM(NSUInteger, OCTToxWrapperUserStatus) {
    OCTToxWrapperUserStatusNone,
    OCTToxWrapperUserStatusAway,
    OCTToxWrapperUserStatusBusy,
    OCTToxWrapperUserStatusInvalid,
};

/**
 * Simple wrapper for all functions from tox.h file.
 */
@interface OCTToxWrapper : NSObject

#pragma mark -  Tox methods

/**
 * Run this funciton at startup. Initializes a tox structure.
 *
 * @param IPv6Enabled Indicates if IPv6 should be used.
 * @param UDPEnabled Indicates if UDP should be used.
 *
 * @return Returns allocated instance of tox on success, NULL on failure.
 */
+ (Tox *)toxNewWithIPv6Enabled:(BOOL)IPv6Enabled UDPEnabled:(BOOL)UDPEnabled;

/**
 * Run this funciton at startup. Initializes a tox structure.
 *
 * @param IPv6Enabled Indicates if IPv6 should be used.
 * @param UDPEnabled Indicates if UDP should be used.
 * @param proxyType Proxy type to be used.
 * @param proxyAddress Ip or domain to be used as proxy.
 * @param proxyPort Proxy port in host byte order.
 *
 * @return Returns allocated instance of tox on success, NULL on failure.
 */
+ (Tox *)toxNewWithIPv6Enabled:(BOOL)IPv6Enabled
                    UDPEnabled:(BOOL)UDPEnabled
                     proxyType:(OCTToxWrapperProxyType)proxyType
                  proxyAddress:(NSString *)proxyAddress
                     proxyPort:(uint16_t)proxyPort;

/**
 * Resolves address into an IP address. If successful, sends a "get nodes" request to the given node with ip,
 * port (in host byte order) and publicKey to setup connections.
 *
 * @param tox Tox structure to work with.
 * @param address Address can be a hostname or an IP address (IPv4 or IPv6).
 * @param port Port in host byte order.
 * @param publicKey Public key of the node.
 *
 * @return YES if address could be converted info an IP address, NO otherwise.
 */
+ (BOOL)toxBootstrapFromAddress:(Tox *)tox
                        address:(NSString *)address
                           port:(uint16_t)port
                      publicKey:(NSString *)publicKey;

/**
 * Like toxBootstrapFromAddress bug for TCP relays only.
 *
 * @param tox Tox structure to work with.
 * @param address Address can be a hostname or an IP address (IPv4 or IPv6).
 * @param port Port in host byte order.
 * @param publicKey Public key of the node.
 *
 * @return YES if address could be converted info an IP address, NO otherwise.
 */
+ (BOOL)toxAddTCPRelay:(Tox *)tox
                  address:(NSString *)address
                     port:(uint16_t)port
                publicKey:(NSString *)publicKey;

/**
 * Checks if we connected to the DHT.
 *
 * @param tox Tox structure to work with.
 *
 * @return YES if connected, otherwise NO
 */
+ (BOOL)toxIsConnected:(const Tox *)tox;

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

/**
 * Set our user status.
 *
 * @param tox Tox structure to work with.
 * @param status Status to be set.
 *
 * @return YES on success, NO on failure.
 */
+ (BOOL)toxSetUserStatus:(Tox *)tox status:(OCTToxWrapperUserStatus)status;

/**
 * Get status message of a friend.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to get status message.
 *
 * @return Status message of a friend.
 */
+ (NSString *)toxGetFriendStatusMessage:(const Tox *)tox friendNumber:(int32_t)friendNumber;

/**
 * Get our status message.
 *
 * @param tox Tox structure to work with.
 *
 * @return Our status message.
 */
+ (NSString *)toxGetSelfStatusMessage:(const Tox *)tox;

/**
 * Get date of last time friendNumber was seen online.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to get last online.
 *
 * @return Date of last time friend was seen online.
 */
+ (NSDate *)toxGetLastOnline:(const Tox *)tox friendNumber:(int32_t)friendNumber;

/**
 * Set our typing status for a friend. You are responsible for turning it on or off.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to set typing status.
 * @param isTyping Status showing whether user is typing or not.
 *
 * @return YES on success, NO on failure.
 */
+ (BOOL)toxSetUserIsTyping:(Tox *)tox friendNumber:(int32_t)friendNumber isTyping:(BOOL)isTyping;

/**
 * Get the typing status of a friend.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to get typing status.
 *
 * @return YES if friend is typing, otherwise NO.
 */
+ (BOOL)toxGetIsFriendTyping:(const Tox *)tox friendNumber:(int32_t)friendNumber;

/**
 * Return the number of friends.
 *
 * @param tox Tox structure to work with.
 *
 * @return Return the number of friends.
 */
+ (NSUInteger)toxCountFriendList:(const Tox *)tox;

/**
 * Return the number of friends online.
 *
 * @param tox Tox structure to work with.
 *
 * @return Return the number of friends online.
 */
+ (NSUInteger)toxGetNumberOnlineFriends:(const Tox *)tox;

/**
 * Return an array of valid friend IDs.
 *
 * @param tox Tox structure to work with.
 *
 * @return Return an array of valid friend IDs. Array contain NSNumbers with IDs.
 */
+ (NSArray *)toxGetFriendList:(const Tox *)tox;

/**
 * Set avatar for current user.
 * This should be made before connecting, so we will not announce that the user have no avatar
 * before setting and announcing a new one, forcing the peers to re-download it.
 *
 * @param tox Tox structure to work with.
 * @param data Avatar data. Data should be <= that length `+getMaximumDataLengthForType:` with
 * OCTToxWrapperDataLengthTypeAvatar type.
 *
 * @return YES on success, otherwise NO.
 *
 * @warning Data should be <= that length `+maximumDataLengthForType:` with
 * OCTToxWrapperDataLengthTypeAvatar type.
 */
+ (BOOL)toxSetAvatar:(Tox *)tox data:(NSData *)data;

/**
 * Unsets the user avatar.
 *
 * @param tox Tox structure to work with.
 *
 * @return YES on success, otherwise NO.
 */
+ (BOOL)toxUnsetAvatar:(Tox *)tox;

/**
 * Generates a cryptographic hash of the given data.
 * This function may be used by clients for any purpose, but is provided primarily for
 * validating cached avatars. This use is highly recommended to avoid unnecessary avatar
 * updates.
 *
 * @param data Data to be hashed
 *
 * @return Hash generated from data.
 */
+ (NSData *)toxHash:(NSData *)data;

#warning Add comment about notification
/**
 * Request avatar information from a friend.
 * Asks a friend to provide their avatar information (hash). The friend may or may not answer this request and,
 * if answered, the information will be provided through the notification TODO.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to request avatar info.
 *
 * @return YES on success, otherwise NO.
 */
+ (BOOL)toxRequestAvatarInfo:(const Tox *)tox friendNumber:(int32_t)friendNumber;

#warning Add comment about notification
/**
 * Request avatar data from a friend.
 * Ask a friend to send their avatar data. The friend may or may not answer this request and,
 * if answered, the data will be provided through the notification TODO.
 *
 * @param tox Tox structure to work with.
 * @param friendNumber Friend number to request avatar data.
 *
 * @return YES on success, otherwise NO.
 */
+ (BOOL)toxRequestAvatarData:(const Tox *)tox friendNumber:(int32_t)friendNumber;

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

/**
 * Maximum length of data for certain type.
 *
 * @param type Type of data.
 *
 * @return Maximum length of data.
 */
+ (NSUInteger)maximumDataLengthForType:(OCTToxWrapperDataLengthType)type;

@end
