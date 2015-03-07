//
//  OCTDefaultSettingsStorage.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 07.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDefaultSettingsStorage.h"

@implementation OCTDefaultSettingsStorage

#pragma mark -  Lifecycle

- (instancetype)initWithUserDefaultsKey:(NSString *)userDefaultsKey
{
    return nil;
}

#pragma mark -  OCTSettingsStorageProtocol

- (void)setObject:(id)object forKey:(NSString *)key
{
}

- (id)objectForKey:(NSString *)key
{
    return nil;
}

@end
