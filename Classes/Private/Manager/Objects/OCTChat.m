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

    return [values copy];
}

#pragma mark -  Public

- (NSDate *)lastReadDate
{
    if (self.lastReadDateInterval <= 0) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:self.lastReadDateInterval];
}

- (NSDate *)lastActivityDate
{
    if (self.lastActivityDateInterval <= 0) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:self.lastActivityDateInterval];
}

- (BOOL)hasUnreadMessages
{
    return (self.lastMessage.dateInterval > self.lastReadDateInterval);
}

@end
