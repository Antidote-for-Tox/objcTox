// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTManagerConfiguration.h"
#import "OCTDefaultFileStorage.h"

static NSString *const kDefaultBaseDirectory = @"me.dvor.objcTox";

@implementation OCTManagerConfiguration

#pragma mark -  Class methods

+ (instancetype)defaultConfiguration
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration new];

    NSString *baseDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    baseDirectory = [baseDirectory stringByAppendingPathComponent:kDefaultBaseDirectory];

    [[NSFileManager defaultManager] createDirectoryAtPath:baseDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    configuration.fileStorage = [[OCTDefaultFileStorage alloc] initWithBaseDirectory:baseDirectory
                                                                  temporaryDirectory:NSTemporaryDirectory()];

    configuration.options = [OCTToxOptions new];
    configuration.options.IPv6Enabled = YES;
    configuration.options.UDPEnabled = YES;
    configuration.options.startPort = 0;
    configuration.options.endPort = 0;
    configuration.options.proxyType = OCTToxProxyTypeNone;
    configuration.options.proxyHost = nil;
    configuration.options.proxyPort = 0;
    configuration.options.tcpPort = 0;

    configuration.importToxSaveFromPath = nil;

    return configuration;
}

#pragma mark -  NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OCTManagerConfiguration *configuration = [[[self class] allocWithZone:zone] init];

    configuration.fileStorage = self.fileStorage;
    configuration.options = [self.options copy];
    configuration.importToxSaveFromPath = [self.importToxSaveFromPath copy];

    return configuration;
}

@end
