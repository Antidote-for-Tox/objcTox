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
@property (assign, nonatomic, readwrite) OCTMessageCallEvent callEvent;

@end

@implementation OCTMessageCall

#pragma mark -  Public

- (NSString *)description
{
    NSString *description = [super description];

    return [description stringByAppendingString:[self typeDescription]];
}

#pragma mark - Private

- (NSString *)typeDescription
{
    NSString *description;
    switch (self.callEvent) {
        case OCTMessageCallEventDial:
            description = @"Call dial";
            break;
        case OCTMessageCallEventEnd:
            description = [[NSString alloc] initWithFormat:@"Call lasted %f seconds", self.callDuration];
            break;
        case OCTMessageCallEventMissed:
            description = @"Call missed";
            break;
    }
    return description;
}

@end
