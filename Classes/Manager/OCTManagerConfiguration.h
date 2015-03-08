//
//  OCTManagerConfiguration.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTSettingsStorageProtocol.h"
#import "OCTToxOptions.h"

@interface OCTManagerConfiguration : NSObject

@property (strong, nonatomic) id<OCTSettingsStorageProtocol> settingsStorage;
@property (strong, nonatomic) OCTToxOptions *options;

+ (instancetype)defaultConfiguration;

@end
