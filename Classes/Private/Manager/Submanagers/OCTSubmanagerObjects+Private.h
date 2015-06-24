//
//  OCTSubmanagerObjects+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTToxDelegate.h"

@interface OCTSubmanagerObjects (Private) <OCTToxDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@end
