//
//  OCTSubmanagerChat+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerChat.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTToxDelegate.h"

@interface OCTSubmanagerChat (Private) <OCTToxDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@end
