//
//  OCTMessageCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/12/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"
#import "OCTManagerConstants.h"

@interface OCTMessageCall : OCTObject

/**
 * The length of the call in seconds.
 **/
@property  NSTimeInterval callDuration;

/**
 * The type of message call.
 **/
@property  OCTMessageCallEvent callEvent;

@end
