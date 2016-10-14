// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTToxOptions.h"

@implementation OCTToxOptions

- (id)copyWithZone:(NSZone *)zone
{
    OCTToxOptions *options = [[[self class] allocWithZone:zone] init];

    options.IPv6Enabled = self.IPv6Enabled;
    options.UDPEnabled = self.UDPEnabled;

    options.startPort = self.startPort;
    options.endPort = self.endPort;

    options.proxyType = self.proxyType;
    options.proxyHost = [self.proxyHost copy];
    options.proxyPort = self.proxyPort;

    options.tcpPort = self.tcpPort;

    return options;
}

@end
