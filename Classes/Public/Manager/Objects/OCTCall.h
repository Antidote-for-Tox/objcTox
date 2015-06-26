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
#import "OCTManagerConstants.h"

/**
 * Please note that all properties of this object are readonly.
 * All management of calls are handeled through OCTCallSubmanagerCalls.
 */
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
 * We are sending audio to the other client.
 */
@property BOOL sendingAudio;

/**
 * We are sending video to the other client.
 */
@property BOOL sendingVideo;

/**
 * We are receiving audio to the other client.
 */
@property BOOL receivingAudio;

/**
 * We are receiving video to the other client.
 */
@property BOOL receivingVideo;

/**
 * Call duration
 **/
@property NSTimeInterval callDuration;

@end
