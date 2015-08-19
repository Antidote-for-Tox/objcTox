//
//  OCTNode.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"

@interface OCTNode : NSObject

@property (strong, nonatomic, readonly) NSString *host;
@property (assign, nonatomic, readonly) OCTToxPort port;
@property (strong, nonatomic, readonly) NSString *publicKey;

- (instancetype)initWithHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end
