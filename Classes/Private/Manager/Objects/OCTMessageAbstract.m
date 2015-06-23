//
//  OCTMessageAbstract.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 14.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageAbstract.h"
#import "OCTMessageText.h"
#import "OCTMessageFile.h"

@interface OCTMessageAbstract ()

@end

@implementation OCTMessageAbstract

#pragma mark -  Public

- (NSDate *)date
{
    return [NSDate dateWithTimeIntervalSince1970:self.dateInterval];
}

- (BOOL)isOutgoing
{
    return (self.sender == nil);
}

- (NSString *)description
{
    NSString *string = nil;

    if (self.messageText) {
        string = [self.messageText description];
    }
    else if (self.messageFile) {
        string = [self.messageFile description];
    }

    return [NSString stringWithFormat:@"OCTMessageAbstract with date %@, %@", self.date, string];
}

@end
