//
//  OCTChat.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 25.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChat.h"
#import "OCTChat+Private.h"
#import "OCTMessageAbstract.h"

@interface OCTChat ()

@property (copy, nonatomic, readwrite) NSString *uniqueIdentifier;

@property (strong, nonatomic, readwrite) NSArray *friends;
@property (strong, nonatomic, readwrite) OCTMessageAbstract *lastMessage;

@property (copy, nonatomic) void (^enteredTextUpdateBlock)(NSString *enteredText);
@property (copy, nonatomic) void (^lastReadDateUpdateBlock)(NSDate *lastReadDate);

@end

@implementation OCTChat

#pragma mark -  Properties

- (void)setEnteredText:(NSString *)enteredText
{
    _enteredText = enteredText;

    if (self.enteredTextUpdateBlock) {
        self.enteredTextUpdateBlock(enteredText);
    }
}

- (void)setLastReadDate:(NSDate *)date
{
    _lastReadDate = date;

    if (self.lastReadDateUpdateBlock) {
        self.lastReadDateUpdateBlock(date);
    }
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCTChat with identifier %@", self.uniqueIdentifier];
}

#pragma mark - Private

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (! [object isKindOfClass:[OCTChat class]]) {
        return NO;
    }

    OCTChat *otherChat = object;

    return [self.uniqueIdentifier isEqual:otherChat.uniqueIdentifier];
}

- (NSUInteger)hash
{
    return [self.uniqueIdentifier hash];
}

@end
