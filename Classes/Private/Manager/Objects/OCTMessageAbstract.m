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
#import "OCTMessageCall.h"

@interface OCTMessageAbstract ()

@end

@implementation OCTMessageAbstract

#pragma mark -  Public

- (NSDate *)date
{
    if (self.dateInterval <= 0) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:self.dateInterval];
}

- (BOOL)isOutgoing
{
    return (self.senderUniqueIdentifier == nil);
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
    else if (self.messageCall) {
        string = [self.messageCall description];
    }

    return [NSString stringWithFormat:@"OCTMessageAbstract with date %@, %@", self.date, string];
}

@end
