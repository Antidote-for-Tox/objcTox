//
//  OCTToxOptions.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTToxOptions.h"

@implementation OCTToxOptions

- (id)copyWithZone:(NSZone *)zone
{
    OCTToxOptions *options = [[[self class] allocWithZone:zone] init];

    options.IPv6Enabled = self.IPv6Enabled;
    options.UDPEnabled = self.UDPEnabled;

    options.proxyType = self.proxyType;
    options.proxyAddress = [self.proxyAddress copy];
    options.proxyPort = self.proxyPort;

    return options;
}

@end
