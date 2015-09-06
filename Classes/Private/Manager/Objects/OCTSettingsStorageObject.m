//
//  OCTSettingsStorageObject.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 03/09/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSettingsStorageObject.h"

@implementation OCTSettingsStorageObject

+ (NSDictionary *)defaultPropertyValues
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super defaultPropertyValues]];

    dict[@"bootstrapDidConnect"] = @NO;
    return [dict copy];
}

@end
