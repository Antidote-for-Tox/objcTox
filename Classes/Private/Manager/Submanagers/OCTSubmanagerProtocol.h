//
//  OCTSubmanagerProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerDataSource.h"
#import "OCTToxDelegate.h"

@protocol OCTSubmanagerProtocol <OCTToxDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@optional

- (void)configure;

@end
