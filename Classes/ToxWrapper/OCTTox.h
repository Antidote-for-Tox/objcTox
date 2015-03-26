//
//  OCTTox.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxDelegate.h"
#import "OCTToxOptions.h"
#import "OCTToxConstants.h"

@interface OCTTox : NSObject

@property (weak, nonatomic) id<OCTToxDelegate> delegate;

/**
 * Indicates if we are connected to the DHT.
 */
@property (assign, nonatomic, readonly) OCTToxConnectionStatus connectionStatus;

/**
 * Our address.
 *
 * Address for Tox as a hex string. Address is kOCTToxAddressLength length and has following format:
 * [public_key (32 bytes, 64 characters)][nospam number (4 bytes, 8 characters)][checksum (2 bytes, 4 characters)]
 */
@property (strong, nonatomic, readonly) NSString *userAddress;

/**
 * Client's user status.
 */
@property (assign, nonatomic) OCTToxUserStatus userStatus;

#pragma mark -  Class methods

/**
 * Return toxcore version in format X.Y.Z, where
 * X - The major version number. Incremented when the API or ABI changes in an incompatible way.
 * Y - The minor version number. Incremented when functionality is added without breaking the API or ABI.
 * Set to 0 when the major version number is incremented.
 * Z - The patch or revision number. Incremented when bugfixes are applied without changing any functionality or API or ABI.
 */
+ (NSString *)version;

/**
 * The major version number of toxcore. Incremented when the API or ABI changes in an incompatible way.
 */
+ (NSUInteger)versionMajor;

/**
 * The minor version number of toxcore. Incremented when functionality is added without breaking the API or ABI.
 * Set to 0 when the major version number is incremented.
 */
+ (NSUInteger)versionMinor;

/**
 * The patch or revision number of toxcore. Incremented when bugfixes are applied without changing any functionality or API or ABI.
 */
+ (NSUInteger)versionPath;

#pragma mark -  Lifecycle

/**
 * Creates new Tox object with configuration options and loads saved data.
 *
 * @param options Configuration options.
 * @param data Data load Tox from previously stored by `-save` method. Pass nil if there is no saved data.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorInitCode for all error codes.
 *
 * @return New instance of Tox or nil if fatal error occured during loading.
 *
 * @warning If loading failed or succeeded only partially, the new or partially loaded instance is returned and
 * an error is set.
 */
- (instancetype)initWithOptions:(OCTToxOptions *)options savedData:(NSData *)data error:(NSError **)error;

/**
 * Saves Tox into NSData.
 *
 * @return NSData with Tox save.
 */
- (NSData *)save;

/**
 * Starts the main loop of the Tox.
 *
 * @warning Tox won't do anything without calling this method.
 */
- (void)start;

/**
 * Stops the main loop of the Tox.
 */
- (void)stop;

#pragma mark -  Methods

/**
 * Sends a "get nodes" request to the given bootstrap node with IP, port, and
 * public key to setup connections.
 *
 * This function will attempt to connect to the node using UDP and TCP at the
 * same time.
 *
 * Tox will use the node as a TCP relay in case OCTToxOptions.UDPEnabled was
 * YES, and also to connect to friends that are in TCP-only mode. Tox will
 * also use the TCP connection when NAT hole punching is slow, and later switch
 * to UDP if hole punching succeeds.
 *
 * @param host The hostname or an IP address (IPv4 or IPv6) of the node.
 * @param port The port on the host on which the bootstrap Tox instance is listening.
 * @param publicKey Public key of the node (of kOCTToxPublicKeyLength length).
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorBootstrapCode for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)bootstrapFromHost:(NSString *)host port:(uint16_t)port publicKey:(NSString *)publicKey error:(NSError **)error;

/**
 * Adds additional host:port pair as TCP relay.
 *
 * This function can be used to initiate TCP connections to different ports on
 * the same bootstrap node, or to add TCP relays without using them as
 * bootstrap nodes.
 *
 * @param host The hostname or IP address (IPv4 or IPv6) of the TCP relay.
 * @param port The port on the host on which the TCP relay is listening.
 * @param publicKey Public key of the node (of kOCTToxPublicKeyLength length).
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorBootstrapCode for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)addTCPRelayWithHost:(NSString *)host port:(uint16_t)port publicKey:(NSString *)publicKey error:(NSError **)error;

/**
 * Add a friend.
 *
 * @param address Address of a friend to add. Must be exactry kOCTToxAddressLength length.
 * @param message Message that would be send with friend request. Minimum length - 1 byte.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendAdd for all error codes.
 *
 * @return On success returns friend number. On failure returns UINT32_MAX and fills `error` parameter.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeFriendRequest type.
 */
- (uint32_t)addFriendWithAddress:(NSString *)address message:(NSString *)message error:(NSError **)error;

/**
 * Add a friend without sending friend request.
 *
 * This function is used to add a friend in response to a friend request. If the
 * client receives a friend request, it can be reasonably sure that the other
 * client added this client as a friend, eliminating the need for a friend
 * request.
 *
 * This function is also useful in a situation where both instances are
 * controlled by the same entity, so that this entity can perform the mutual
 * friend adding. In this case, there is no need for a friend request, either.
 *
 * @param publicKey Public key of a friend to add. Public key is hex string, must be exactry kOCTToxPublicKeyLength length.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendAdd for all error codes.
 *
 * @return On success returns friend number. On failure returns UINT32_MAX.
 */
- (uint32_t)addFriendWithNoRequestWithPublicKey:(NSString *)publicKey error:(NSError **)error;

/**
 * Remove a friend from the friend list.
 *
 * This does not notify the friend of their deletion. After calling this
 * function, this client will appear offline to the friend and no communication
 * can occur between the two.
 *
 * @param friendNumber Friend number to remove.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendDelete for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)deleteFriendWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Return the friend number associated with that Public Key.
 *
 * @param publicKey Public key of a friend. Public key is hex string, must be exactry kOCTToxPublicKeyLength length.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendByPublicKey for all error codes.
 *
 * @return The friend number on success, UINT32_MAX on failure.
 */
- (uint32_t)friendNumberWithPublicKey:(NSString *)publicKey error:(NSError **)error;

/**
 * Get public key from associated friend number.
 *
 * @param friendNumber Associated friend number
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendGetPublicKey for all error codes.
 *
 * @return Public key of a friend. Public key is hex string, must be exactry kOCTToxPublicKeyLength length. If there is no such friend returns nil.
 */
- (NSString *)publicKeyFromFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Checks if there exists a friend with given friendNumber.
 *
 * @param friendNumber Friend number to check.
 *
 * @return YES if friend exists, NO otherwise.
 */
- (BOOL)friendExistsWithFriendNumber:(uint32_t)friendNumber;

/**
 * Return the friend's user status (away/busy/...). If the friend number is
 * invalid, the return value is unspecified.
 *
 * @param friendNumber Friend number to check status.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendQuery for all error codes.
 *
 * @return Returns friend status.
 */
- (OCTToxUserStatus)friendStatusWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Check whether a friend is currently connected to this client.
 *
 * @param friendNumber Friend number to check status.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendQuery for all error codes.
 *
 * @return Returns friend connection status.
 */
- (OCTToxConnectionStatus)friendConnectionStatusWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Send a text chat message to an online friend.
 *
 * @param friendNumber Friend number to send a message.
 * @param type Type of the message.
 * @param message Message that would be send.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendSendMessage for all error codes.
 *
 * @return The message id if packet was successfully put into the send queue, 0 if it was not. You can use id later to check if message has been delivered.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeSendMessage type.
 */
- (uint32_t)sendMessageWithFriendNumber:(uint32_t)friendNumber
                                   type:(OCTToxMessageType)type
                                message:(NSString *)message
                                  error:(NSError **)error;

/**
 * Set the nickname for the Tox client.
 *
 * @param name Name to be set. Minimum length of name is 1 byte.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorSetInfoCode for all error codes.
 *
 * @return YES on success, NO on failure.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeName type.
 */
- (BOOL)setNickname:(NSString *)name error:(NSError **)error;

/**
 * Get your nickname.
 *
 * @return Your nickname or nil in case of error.
 */
- (NSString *)userName;

/**
 * Get name of friendNumber.
 *
 * @param friendNumber Friend number to get name.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendQuery for all error codes.
 *
 * @return Name of friend or nil in case of error.
 */
- (NSString *)friendNameWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Set our status message.
 *
 * @param statusMessage Status message to be set.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorSetInfoCode for all error codes.
 *
 * @return YES on success, NO on failure.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeStatusMessage type.
 */
- (BOOL)setUserStatusMessage:(NSString *)statusMessage error:(NSError **)error;

/**
 * Get our status message.
 *
 * @return Our status message.
 */
- (NSString *)userStatusMessage;

/**
 * Get status message of a friend.
 *
 * @param friendNumber Friend number to get status message.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendQuery for all error codes.
 *
 * @return Status message of a friend.
 */
- (NSString *)friendStatusMessageWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Get date of last time friendNumber was seen online.
 *
 * @param friendNumber Friend number to get last online.
 *
 * @return Date of last time friend was seen online.
 */
- (NSDate *)lastOnlineWithFriendNumber:(uint32_t)friendNumber;

/**
 * Set our typing status for a friend. You are responsible for turning it on or off.
 *
 * @param isTyping Status showing whether user is typing or not.
 * @param friendNumber Friend number to set typing status.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorSetTyping for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)setUserIsTyping:(BOOL)isTyping forFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Get the typing status of a friend.
 *
 * @param friendNumber Friend number to get typing status.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorFriendQuery for all error codes.
 *
 * @return YES if friend is typing, otherwise NO.
 */
- (BOOL)isFriendTypingWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error;

/**
 * Return the number of friends.
 *
 * @return Return the number of friends.
 */
- (NSUInteger)friendsCount;

/**
 * Return the number of friends online.
 *
 * @return Return the number of friends online.
 */
- (NSUInteger)friendsOnlineCount;

/**
 * Return an array of valid friend IDs.
 *
 * @return Return an array of valid friend IDs. Array contain NSNumbers with IDs.
 */
- (NSArray *)friendsArray;

/**
 * Set avatar for current user.
 * This should be made before connecting, so we will not announce that the user have no avatar
 * before setting and announcing a new one, forcing the peers to re-download it.
 *
 * @param data Avatar data. Data should be <= that length `-getMaximumDataLengthForType:` with
 * OCTToxDataLengthTypeAvatar type. You can pass nil to remove avatar. Avatar should be PNG representation of image.
 *
 * @return YES on success, otherwise NO.
 *
 * @warning Data should be <= that length `-maximumDataLengthForType:` with OCTToxDataLengthTypeAvatar type.
 * @warning Avatar should be PNG representation of image
 */
- (BOOL)setAvatar:(NSData *)data;

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
- (NSData *)hashData:(NSData *)data;

/**
 * Request avatar information from a friend.
 * Asks a friend to provide their avatar information (hash). The friend may or may not answer this request and,
 * if answered, the information will be provided through the delegate method `tox:friendAvatarHashUpdate:friendNumber:`.
 *
 * @param friendNumber Friend number to request avatar info.
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)requestAvatarHashWithFriendNumber:(uint32_t)friendNumber;

/**
 * Request avatar data from a friend.
 * Ask a friend to send their avatar data. The friend may or may not answer this request and,
 * if answered, the data will be provided through the delegate method `tox:friendAvatarUpdate:hash:friendNumber:`.
 *
 * @param friendNumber Friend number to request avatar data.
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)requestAvatarDataWithFriendNumber:(uint32_t)friendNumber;

/**
 * Send an unrequested avatar information to a friend. Sends our avatar format and hash to a friend; he/she
 * can use this information to validate an avatar from the cache and may (or not) reply with an avatar
 * data request.
 * Notice: it is NOT necessary to send these notification after changing the avatar or connecting. The library already does this.
 *
 * @param friendNumber Friend number to send avatar info
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)sendAvatarInfoToFriendNumber:(uint32_t)friendNumber;

/**
 * Send a file send request.
 *
 * @param friendNumber Friend number to send file
 * @param fileName Name of file to be sent
 * @param fileSize Size of file to be sent
 *
 * @return file number on success, -1 on failure
 */
- (int)fileSendRequestWithFriendNumber:(uint32_t)friendNumber fileName:(NSString *)fileName fileSize:(uint64_t)fileSize;

/**
 * Send a file control request
 *
 * @param friendNumber Friend number to send/receive file
 * @param sendOrReceive Type of action on file. It is OCTToxFileControlTypeSend if we want the control packet to target a file we
 * are currently sending, OCTToxFileControlTypeReceive - if it targets a file we are currently receiving.
 * @param fileNumber Number of file to be sent/received
 * @param controlType Type of file control
 * @param data Pointer on data
 *
 * @return YES on success, NO on failure
 */
- (BOOL)fileSendControlWithFriendNumber:(uint32_t)friendNumber
                          sendOrReceive:(OCTToxFileControlType)sendOrReceive
                             fileNumber:(uint8_t)fileNumber
                            controlType:(OCTToxFileControl)controlType
                                   data:(NSData *)data;

/**
 * Send file data
 *
 * @param friendNumber Friend number to send/receive file
 * @param fileNumber Number of file to be sent/received
 * @param data Pointer on data
 *
 * @return YES on success, NO on failure
 */
- (BOOL)fileSendDataWithFriendNumber:(uint32_t)friendNumber fileNumber:(uint8_t)fileNumber data:(NSData *)data;

/**
 * Calculate the recommended/maximum size of the filedata you send
 *
 * @param friendNumber Friend number to send/receive file
 *
 * @return recommended/maximum size of the filedata, -1 on failure
 */
- (int)fileDataSizeWithFriendNumber:(uint32_t)friendNumber;

/**
 * Get a number of bytes left to be sent or received
 *
 * @param friendNumber Friend number to send/receive file
 * @param fileName Name of file to be sent/received
 * @param sendOrReceive OCTToxFileControlTypeSend - for sending a file, OCTToxFileControlTypeReceive - for receiving a file
 *
 * @return file number on success, 0 on failure
 */
- (uint64_t)fileDataRemainingWithFriendNumber:(uint32_t)friendNumber
                                   fileNumber:(uint8_t)fileNumber
                                sendOrReceive:(OCTToxFileControlType)sendOrReceive;

#pragma mark -  Helper methods

/**
 * Checks length of string against maximum length  for specified type.
 *
 * @param string String to check.
 * @param type Type used to check string. Different types have different maximun length.
 *
 * @return YES, if string <= maximum length, NO otherwise.
 */
- (BOOL)checkLengthOfString:(NSString *)string withCheckType:(OCTToxCheckLengthType)type;

/**
 * Crops string to fit maximum length for specified type.
 *
 * @param string String to crop.
 * @param type Type used to check string. Different types have different maximun length.
 *
 * @return The new cropped string.
 */
- (NSString *)cropString:(NSString *)string toFitType:(OCTToxCheckLengthType)type;

/**
 * Maximum length of data for certain type.
 *
 * @param type Type of data.
 *
 * @return Maximum length of data.
 */
- (NSUInteger)maximumDataLengthForType:(OCTToxDataLengthType)type;

@end
