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
@property (assign, nonatomic, readwrite) OCTMessageCallType callType;

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
    switch (self.callType) {
        case OCTMessageCallTypeDial:
            description = @"Call dial";
            break;
        case OCTMessageCallTypeEnd:
            description = [[NSString alloc] initWithFormat:@"Call ended %f seconds", self.callDuration];
            break;
        case OCTMessageCallTypeMissed:
            description = @"Call missed";
            break;
        default:
            break;
    }
    return description;
}

@end
