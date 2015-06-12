//
//  OCTSubmanagerCalls+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/4/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls.h"
#import "OCTDBManager.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTToxAV.h"
#import "OCTAudioEngine.h"
#import "OCTConverterChat.h"
#import "OCTCall+Private.h"
#import "OCTArray+Private.h"
#import "OCTCallsContainer+Private.h"

@class OCTTox;

@interface OCTSubmanagerCalls (Private)

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

/**
 * Initialize the OCTSubmanagerCall
 *
 */
- (instancetype)initWithTox:(OCTTox *)tox;

@end
