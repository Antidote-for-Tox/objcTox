// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"
#import "OCTManagerConstants.h"

NS_ASSUME_NONNULL_BEGIN
@class OCTManagerConfiguration;

@class OCTSubmanagerBootstrap;
@class OCTSubmanagerCalls;
@class OCTSubmanagerChats;
@class OCTSubmanagerDNS;
@class OCTSubmanagerFiles;
@class OCTSubmanagerFriends;
@class OCTSubmanagerObjects;
@class OCTSubmanagerUser;

@protocol OCTManager <NSObject>

/**
 * Submanager responsible for connecting to other nodes.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerBootstrap *bootstrap;

/**
 * Submanager with all video/calling methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerCalls *calls;

/**
 * Submanager with all chats methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerChats *chats;

/**
 * Submanager with all DNS methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerDNS *dns;

/**
 * Submanager with all files methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerFiles *files;

/**
 * Submanager with all friends methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerFriends *friends;

/**
 * Submanager with all objects methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerObjects *objects;

/**
 * Submanager with all user methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerUser *user;

/**
 * Configuration used by OCTManager.
 *
 * @return Copy of configuration used by manager.
 */
- (OCTManagerConfiguration *)configuration;

/**
 * Copies tox save file to temporary directory and return path to it.
 *
 * @param error NSFileManager error in case if file cannot be copied.
 *
 * @return Temporary path of current tox save file.
 */
- (nullable NSString *)exportToxSaveFile:(NSError *__nullable *__nullable)error;

/**
 * Set password to encrypt tox save file and database.
 *
 * @param newPassword New password used to encrypt tox save file and database.
 * @param oldPassword Old password.
 *
 * @return YES on success, NO on failure (if old password doesn't match).
 */
- (BOOL)changeEncryptPassword:(nonnull NSString *)newPassword oldPassword:(nonnull NSString *)oldPassword;

/**
 * Checks if manager is encrypted with given password.
 *
 * @param password Password to verify.
 *
 * @return YES if manager is encrypted with given password, NO otherwise.
 */
- (BOOL)isManagerEncryptedWithPassword:(nonnull NSString *)password;

@end

NS_ASSUME_NONNULL_END
