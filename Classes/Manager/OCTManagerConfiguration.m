//
//  OCTManagerConfiguration.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTManagerConfiguration.h"
#import "OCTDefaultSettingsStorage.h"

static NSString *const kDefaultSettingsStorageUserDefaultsKey = @"me.dvor.objcTox.settings";

@implementation OCTManagerConfiguration

+ (instancetype)defaultConfiguration
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration new];

    configuration.settingsStorage = [[OCTDefaultSettingsStorage alloc]
        initWithUserDefaultsKey:kDefaultSettingsStorageUserDefaultsKey];

    configuration.options = [OCTToxOptions new];
    configuration.options.IPv6Enabled = YES;
    configuration.options.UDPEnabled = YES;
    configuration.options.proxyType = OCTToxProxyTypeNone;
    configuration.options.proxyAddress = nil;
    configuration.options.proxyPort = 0;

    return configuration;
}

@end
