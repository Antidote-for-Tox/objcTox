//
//  OCTMessageCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/12/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageCall.h"

@interface OCTMessageCall ()

@property (assign, nonatomic, readwrite) NSTimeInterval callDuration;

@end

@implementation OCTMessageCall

#pragma mark -  Public

- (NSString *)description
{
    NSString *description = [super description];

    return [description stringByAppendingFormat:@"\ncallDuration %f", self.callDuration];
}

@end
