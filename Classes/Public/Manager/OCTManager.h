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
 * Create manager with configuration. There is no way to change configuration after init method. If you'd like to
 * change it you have to recreate OCTManager.
 *
 * @param configuration Configuration to be used.
 * @param error If an error occurs, this pointer is set to an actual error object containing the error information.
 * See OCTToxErrorInitCode for all error codes.
 *
 * @return Initialized OCTManager.
 */
- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration error:(NSError **)error;

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
 */
- (void)changePassphrase:(NSString *)passphrase;

#pragma mark -  Deprecated

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                  loadToxSaveFilePath:(NSString *)toxSaveFilePath
                                error:(NSError **)error
    __attribute((deprecated(("Use initWithConfiguration:error: instead."
                             "toxSaveFilePath parameter moved to OCTManagerConfiguration.importToxSaveFromPath"))));

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
    __attribute((deprecated(("Use initWithConfiguration:error: instead"))));

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                  loadToxSaveFilePath:(NSString *)toxSaveFilePath
    __attribute((deprecated(("Use initWithConfiguration:error: instead."
                             "toxSaveFilePath parameter moved to OCTManagerConfiguration.importToxSaveFromPath"))));

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
- (BOOL)bootstrapFromHost:(NSString *)host
                     port:(OCTToxPort)port
                publicKey:(NSString *)publicKey
                    error:(NSError **)error __attribute((deprecated(("Use bootstrap submanager instead"))));

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
- (BOOL)addTCPRelayWithHost:(NSString *)host
                       port:(OCTToxPort)port
                  publicKey:(NSString *)publicKey
                      error:(NSError **)error __attribute((deprecated(("Use bootstrap submanager instead"))));

@end
