//
//  OCTManager.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 06.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

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

@interface OCTManager : NSObject

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
 * @param path Path to tox save file.
 *
 * @return YES if save file is encrypted. NO if it isn't encrypted OR if file does not exist.
 */
+ (BOOL)isToxSaveEncryptedAtPath:(NSString *)path;

/**
 * Create manager with configuration. There is no way to change configuration after init method. If you'd like to
 * change it you have to recreate OCTManager.
 *
 * @param configuration Configuration to be used.
 * @param toxPassword Password used to decrypt tox save file. You should specify this parameter *only*
 *        if tox save file is already encrypted. If you would like to enable encryption please use OCTManager's method.
 * @param databasePassword Password used to decrypt database. This is a required parameter as database is *always*
 *        encrypted. When creating OCTManager for the first time database will be automatically encrypted with this
 *        key. To change it use appropriate method below.
 *
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTManagerInitError for all error codes.
 *
 * @return Initialized OCTManager.
 */
- (nullable instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                                   toxPassword:(nullable NSString *)toxPassword
                              databasePassword:(NSString *)databasePassword
                                         error:(NSError *__nullable *__nullable)error;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

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
 * Set password to encrypt tox save file.
 *
 * @param newPassword New password used to encrypt tox save file. You can pass nil to disable encryption.
 * @param oldPassword Old password. Pass nil if there is no old password.
 *
 * @return YES on success, NO on failure (if old password doesn't match).
 */
- (BOOL)changeToxPassword:(nullable NSString *)newPassword oldPassword:(nullable NSString *)oldPassword;

/**
 * Change password used to encrypt database.
 *
 * @param newPassword New password used to encrypt database.
 * @param oldPassword Old password.
 *
 * @return YES on success, NO on failure (if old password doesn't match).
 */
- (BOOL)changeDatabasePassword:(NSString *)newPassword oldPassword:(NSString *)oldPassword;

@end

NS_ASSUME_NONNULL_END
