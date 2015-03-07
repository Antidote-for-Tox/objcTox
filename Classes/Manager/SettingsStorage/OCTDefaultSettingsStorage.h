//
//  OCTDefaultSettingsStorage.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 07.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTSettingsStorageProtocol.h"

@interface OCTDefaultSettingsStorage : NSObject <OCTSettingsStorageProtocol>

- (instancetype)initWithUserDefaultsKey:(NSString *)userDefaultsKey;

@end
