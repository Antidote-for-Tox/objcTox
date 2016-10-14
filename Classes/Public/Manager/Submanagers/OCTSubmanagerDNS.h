// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

@interface OCTSubmanagerDNS : NSObject

/**
 * Add server for tox3 DNS discovery.
 *
 * @param domain Domain of server to add.
 * @param publicKey Public key of server.
 */
- (void)addTox3Server:(nonnull NSString *)domain publicKey:(nonnull NSString *)publicKey;

/**
 * Add predefined servers. objcTox is trying to keep this list up to date.
 * You can check all servers in OCTPredefined file.
 */
- (void)addPredefinedTox3Servers;

/**
 * Perform tox3 DNS discovery for given string. Discovery will be performed only with previously
 * added servers with `addTox3Server:publicKey:` or `addPredefinedTox3Servers` methods.
 *
 * @param string String to resolve. Should have following format: user@domain
 * @param successBlock Block called on success.
 * @param failureBlock Block called on discovery failure.
 */
- (void)tox3DiscoveryForString:(nonnull NSString *)string
                       success:(nullable void (^)(NSString *__nonnull toxId))successBlock
                       failure:(nullable void (^)(NSError *__nonnull error))failureBlock;

/**
 * Perform tox1 DNS discovery for given string.
 *
 * @param string String to resolve. Should have following format: user@domain
 * @param successBlock Block called on success.
 * @param failureBlock Block called on discovery failure.
 */
- (void)tox1DiscoveryForString:(nonnull NSString *)string
                       success:(nullable void (^)(NSString *__nonnull toxId))successBlock
                       failure:(nullable void (^)(NSError *__nonnull error))failureBlock;

@end
