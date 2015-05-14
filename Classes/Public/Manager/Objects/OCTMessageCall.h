//
//  OCTMessageCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/12/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageAbstract.h"

@interface OCTMessageCall : OCTMessageAbstract

/**
 * The time the call ended.
 **/
@property (strong, nonatomic, readonly) NSDate* endTime;

/**
 * The duration of the call
 * @return duration of the call in seconds.
 */
- (NSTimeInterval)callDuration;

@end
