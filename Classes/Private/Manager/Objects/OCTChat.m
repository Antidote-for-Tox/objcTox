//
//  OCTChat.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 25.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChat.h"
#import "OCTMessageAbstract.h"

@interface OCTChat ()

@end

@implementation OCTChat

#pragma mark -  Class methods

+ (NSDictionary *)defaultPropertyValues
{
    NSMutableDictionary *values = [NSMutableDictionary dictionaryWithDictionary:[super defaultPropertyValues]];
    values[@"enteredText"] = @"";
    values[@"lastReadDate"] = [NSDate dateWithTimeIntervalSince1970:0];

    return [values copy];
}

#pragma mark -  Public

- (BOOL)hasUnreadMessages
{
    NSDate *messageDate = self.lastMessage.date;

    if (! messageDate) {
        return NO;
    }

    if (! self.lastReadDate) {
        // We have lastMessage but don't have lastReadDate
        return YES;
    }

    NSComparisonResult result = [messageDate compare:self.lastReadDate];

    return (result == NSOrderedDescending);
}

- (NSDate *)lastActivityDate
{
    if (self.lastMessage) {
        return [self.lastMessage date];
    }

    return self.creationDate;
}

@end
