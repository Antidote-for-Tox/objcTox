//
//  OCTCallSubmanager.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "OCTChat.h"
#include "OCTCall.h"
#include "OCTArray.h"

@class OCTCallSubmanager;

@protocol OCTCallSubmanagerDelegate <NSObject>

- (void)receiveCallFrom:(OCTFriend *)friend audioEnabled:(BOOL)audioEnabled videoEnabled:(BOOL)videoEnabled;

@end

@interface OCTCallSubmanager : NSObject

/**
 * Call sessions that are active.
 */
@property (strong, nonatomic, readonly) OCTArray *calls;
/**
 * This class is responsible for telling the end-user what calls we have available.
 * We can also initialize a call session from here.
 */
- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo dataSource:()dataSource;

/**
 * Answer a call
 * @param error Pointer to an error when attempting to answer a call
 * @return OCTCall session that end-user can manage. Nil if failed to answer call.
 **/
- (OCTCall *)answerCall:(OCTFriend *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError**)error;

@end
