//
//  OCTPredefined.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCTPredefined : NSObject

/**
 * A list of nodes from https://wiki.tox.chat/users/nodes
 *
 * See OCTSubmanagerBootstrap for more information.
 *
 * Updated 2015-08-05.
 */
+ (NSArray *)bootstrapNodes;

/**
 * A list of servers for Tox3 DNS discovery.
 *
 * See OCTSubmanagerDNS for more information.
 *
 * Updated 2015-08-21.
 */
+ (NSArray *)tox3Servers;

@end
