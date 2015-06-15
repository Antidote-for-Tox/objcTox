//
//  OCTMessageCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/12/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageAbstract.h"
#import "OCTManagerConstants.h"

@interface OCTMessageCall : OCTMessageAbstract

/**
 * The length of the call in seconds.
 **/
@property (assign, nonatomic, readonly) NSTimeInterval callDuration;

/**
 * The type of message call.
 **/
@property (assign, nonatomic, readonly) OCTMessageCallType callType;

@end
