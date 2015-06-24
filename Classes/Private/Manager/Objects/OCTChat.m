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

- (NSDate *)creationDate
{
    if (self.creationDateInterval <= 0) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:self.creationDateInterval];
}

- (BOOL)hasUnreadMessages
{
    return (self.lastMessage.dateInterval > self.lastReadDateInterval);
}

- (NSDate *)lastActivityDate
{
    if (self.lastMessage) {
        return [self.lastMessage date];
    }

    return self.creationDate;
}

@end
