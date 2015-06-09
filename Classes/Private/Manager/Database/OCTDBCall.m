//
//  OCTDBCall.m
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBCall.h"

@implementation OCTDBCall

- (BOOL)isEqual:(OCTDBCall *)object
{
    return self.chat.uniqueIdentifier == object.chat.uniqueIdentifier;
}

@end
