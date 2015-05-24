//
//  OCTSubmanagerFiles.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFiles+Private.h"

@interface OCTSubmanagerFiles()

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@end

@implementation OCTSubmanagerFiles

#pragma mark -  Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    return self;
}

@end
