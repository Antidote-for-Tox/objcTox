//
//  OCTMessageCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/12/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageCall.h"

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
        case OCTMessageCallEventAnswered:
            description = [[NSString alloc] initWithFormat:@"Call lasted %f seconds", self.callDuration];
            break;
        case OCTMessageCallEventUnanswered:
            description = @"Call missed";
            break;
    }
    return description;
}

@end
