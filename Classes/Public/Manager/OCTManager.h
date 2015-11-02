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

@class OCTManagerConfiguration;

@class OCTSubmanagerAvatars;
@class OCTSubmanagerBootstrap;
@class OCTSubmanagerChats;
@class OCTSubmanagerDNS;
@class OCTSubmanagerFiles;
@class OCTSubmanagerFriends;
@class OCTSubmanagerObjects;
@class OCTSubmanagerUser;

@interface OCTManager : NSObject

/**
 * Submanager with all user avatar methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerAvatars *avatars;

/**
 * Submanager responsible for connecting to other nodes.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerBootstrap *bootstrap;

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
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTManagerInitError for all error codes.
 *
 * @return Initialized OCTManager.
 */
- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration error:(NSError **)error;

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
- (NSString *)exportToxSaveFile:(NSError **)error;

/**
 * Set passphrase to encrypt tox save file.
 *
 * @param passphrase You can pass nil to disable encryption.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)changePassphrase:(NSString *)passphrase;

@end
