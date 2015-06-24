//
//  OCTCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTChat.h"
#import "OCTFriend.h"
#import "OCTToxAVConstants.h"

typedef NS_ENUM(NSInteger, OCTCallStatus) {
    OCTCallStatusInactive = 0,
    OCTCallStatusDialing,
    OCTCallStatusIncoming,
    OCTCallStatusInSession,
};

@interface OCTCall : OCTObject

/**
 * OCTChat related session with the call.
 **/
@property OCTChat *chat;

/**
 * Call status
 **/
@property OCTCallStatus status;

/**
 * Call state of friend.
 **/
@property OCTToxAVCallState state;

/**
 * Call duration
 **/
@property NSTimeInterval callDuration;

@end
