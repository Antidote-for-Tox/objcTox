//
//  OCTSubmanagerUser.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTToxConstants.h"

@class OCTSubmanagerUser;
@protocol OCTSubmanagerUserDelegate <NSObject>
- (void)submanagerUser:(nonnull OCTSubmanagerUser *)submanager connectionStatusUpdate:(OCTToxConnectionStatus)connectionStatus;
@end

@interface OCTSubmanagerUser : NSObject

@property (weak, nonatomic, nullable) id<OCTSubmanagerUserDelegate> delegate;

/**
 * Indicates if client is connected to the DHT.
 */
@property (assign, nonatomic, readonly) OCTToxConnectionStatus connectionStatus;

/**
 * Client's address.
 *
 * Address for Tox as a hex string. Address is kOCTToxAddressLength length and has following format:
 * [publicKey (32 bytes, 64 characters)][nospam number (4 bytes, 8 characters)][checksum (2 bytes, 4 characters)]
 */
@property (strong, nonatomic, readonly, nonnull) NSString *userAddress;

/**
 * Client's Tox Public Key (long term public key) of kOCTToxPublicKeyLength.
 */
@property (strong, nonatomic, readonly, nonnull) NSString *publicKey;

/**
 * Client's nospam part of the address. Any 32 bit unsigned integer.
 */
@property (assign, nonatomic) OCTToxNoSpam nospam;

/**
 * Client's user status.
 */
@property (assign, nonatomic) OCTToxUserStatus userStatus;

/**
 * Set the nickname for the client.
 *
 * @param name Name to be set. Minimum length of name is 1 byte.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorSetInfoCode for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)setUserName:(nullable NSString *)name error:(NSError *__nullable *__nullable)error;

/**
 * Get client's nickname.
 *
 * @return Client's nickname or nil in case of error.
 */
- (nullable NSString *)userName;

/**
 * Set client's status message.
 *
 * @param statusMessage Status message to be set.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorSetInfoCode for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)setUserStatusMessage:(nullable NSString *)statusMessage error:(NSError *__nullable *__nullable)error;

/**
 * Get client's status message.
 *
 * @return Client's status message.
 */
- (nullable NSString *)userStatusMessage;

/**
 * Set user avatar. Avatar should be <= kOCTManagerMaxAvatarSize.
 *
 * @param avatar NSData representation of avatar image.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTSetUserAvatarError for all error codes.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)setUserAvatar:(NSData *)avatar error:(NSError *__nullable *__nullable)error;

/**
 * Get data representation of user avatar.
 *
 * @return Data with user avatar if exists.
 */
- (nullable NSData *)userAvatar;

@end
