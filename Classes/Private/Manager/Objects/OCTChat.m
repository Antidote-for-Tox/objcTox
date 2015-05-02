//
//  OCTChat.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 25.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChat.h"
#import "OCTChat+Private.h"

@interface OCTChat()

@property (strong, nonatomic, readwrite) NSArray *friends;
@property (strong, nonatomic, readwrite) OCTMessageAbstract *lastMessage;

@property (strong, nonatomic) OCTDBChat *dbChat;
@property (weak, nonatomic) OCTDBManager *dbManager;

@end

@implementation OCTChat

#pragma mark -  Properties

- (void)setEnteredText:(NSString *)enteredText
{
    _enteredText = enteredText;

    __weak OCTChat *weakSelf = self;
    [self.dbManager updateDBObjectInBlock:^{
        weakSelf.dbChat.enteredText = enteredText;
    }];
}

- (void)setLastReadDate:(NSDate *)date
{
    _lastReadDate = date;

    __weak OCTChat *weakSelf = self;
    [self.dbManager updateDBObjectInBlock:^{
        weakSelf.dbChat.lastReadDateInterval = [date timeIntervalSince1970];
    }];
}

#pragma mark -  Public

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
