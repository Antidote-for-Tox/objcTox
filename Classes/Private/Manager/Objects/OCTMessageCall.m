//
//  OCTMessageCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/12/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageCall.h"

@interface OCTMessageCall ()

@property (strong, nonatomic, readwrite) NSDate* endTime;

@end

@implementation OCTMessageCall

- (NSTimeInterval)callDuration
{
    return [self.endTime timeIntervalSinceDate:self.date];
}

@end
