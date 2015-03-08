//
//  OCTManager.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 06.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTManager.h"
#import "OCTTox.h"

@interface OCTManager()

@property (strong, nonatomic) OCTTox *tox;
@property (strong, nonatomic) OCTManagerConfiguration *configuration;

@end

@implementation OCTManager

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
{
    NSParameterAssert(configuration.settingsStorage);
    NSParameterAssert(configuration.options);

    self = [super init];

    if (! self) {
        return nil;
    }

    _configuration = configuration;
    _tox = [[OCTTox alloc] initWithOptions:configuration.options];

    return self;
}

@end
