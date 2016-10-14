// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
