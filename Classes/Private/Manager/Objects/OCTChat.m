//
//  OCTChat.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 25.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChat.h"

@interface OCTChat()

@property (strong, nonatomic, readwrite) NSArray *friends;
@property (strong, nonatomic, readwrite) OCTMessageAbstract *lastMessage;

@end

@implementation OCTChat

- (void)updateLastReadDateToNow
{
    self.lastReadDate = [NSDate date];
}

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

@end
