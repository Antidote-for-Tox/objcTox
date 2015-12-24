//
//  OCTSubmanagerBootstrap.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"

@interface OCTSubmanagerBootstrap : NSObject

/**
 * Add node to bootstrap with.
 *
 * This will NOT start bootstrapping. To start actual bootstrapping set all desired nodes
 * and call `bootstrap` method.
 *
 * @param host The hostname or an IP address (IPv4 or IPv6) of the node.
 * @param port The port on the host on which the bootstrap Tox instance is listening.
 * @param publicKey Public key of the node (of kOCTToxPublicKeyLength length).
 */
- (void)addNodeWithHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey;

/**
 * Add nodes from https://wiki.tox.chat/users/nodes. objcTox is trying to keep this list up to date.
 * You can check all nodes in OCTPredefined file.
 *
 * This will NOT start bootstrapping. To start actual bootstrapping set all desired nodes
 * and call `bootstrap` method.
 */
- (void)addPredefinedNodes;

/**
 * You HAVE TO call this method on startup to connect to Tox network.
 *
 * Before calling this method add nodes to bootstrap with.
 *
 * After calling this method
 * - if manager wasn't connected before it will start bootstrapping immediately.
 * - if it was connected before, it will wait 10 to connect to existing nodes
 *   before starting actually bootstrapping.
 *
 * When bootstrapping, submanager will bootstrap 4 random nodes from a list every 5 seconds
 * until is will be connected.
 */
- (void)bootstrap;

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
                      error:(NSError **)error;

@end
