// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTNode.h"

@implementation OCTNode

#pragma mark -  Lifecycle

- (instancetype)initWithHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _host = host;
    _port = port;
    _publicKey = publicKey;

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:[OCTNode class]]) {
        return NO;
    }

    OCTNode *another = object;

    if (! another.host) {
        if (self.host) {
            return NO;
        }
    }

    if (! another.publicKey) {
        if (self.publicKey) {
            return NO;
        }
    }

    return [self.host isEqualToString:another.host] &&
           (self.port == another.port) &&
           [self.publicKey isEqualToString:another.publicKey];
}

- (NSUInteger)hash
{
    const NSUInteger prime = 31;
    NSUInteger result = 1;

    result = prime * result + [self.host hash];
    result = prime * result + self.port;
    result = prime * result + [self.publicKey hash];

    return result;
}

@end
