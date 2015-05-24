//
//  OCTConverterChat.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterChat.h"
#import "OCTChat+Private.h"
#import "OCTDBChat.h"
#import "OCTMessageAbstract+Private.h"

@implementation OCTConverterChat

#pragma mark -  OCTConverterProtocol

- (NSString *)objectClassName
{
    return NSStringFromClass([OCTChat class]);
}

- (NSString *)dbObjectClassName
{
    return NSStringFromClass([OCTDBChat class]);
}

- (id)objectFromRLMObject:(OCTDBChat *)db
{
    NSParameterAssert(db);
    NSParameterAssert(self.converterMessage);
    NSParameterAssert(self.converterFriend);

    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = db.uniqueIdentifier;

    NSMutableArray *friends = [NSMutableArray new];

    for (OCTDBFriend *dbFriend in db.friends) {
        OCTFriend *friend = (OCTFriend *)[self.converterFriend objectFromRLMObject:dbFriend];
        [friends addObject:friend];
    }

    chat.friends = [friends copy];
    if (db.lastMessage) {
        // avoiding retain cycle
        chat.lastMessage = (OCTMessageAbstract *)[self.converterMessage objectFromRLMObjectWithoutChat:db.lastMessage];
        chat.lastMessage.chat = chat;
    }
    chat.enteredText = db.enteredText;
    chat.lastReadDate = [NSDate dateWithTimeIntervalSince1970:db.lastReadDateInterval];

    __weak OCTConverterChat *weakSelf = self;
    chat.enteredTextUpdateBlock = ^(NSString *enteredText) {
        [weakSelf.delegate converterChat:weakSelf updateDBChatWithBlock:^{
            db.enteredText = enteredText;
        }];
    };

    chat.lastReadDateUpdateBlock = ^(NSDate *lastReadDate) {
        [weakSelf.delegate converterChat:weakSelf updateDBChatWithBlock:^{
            db.lastReadDateInterval = [lastReadDate timeIntervalSince1970];
        }];
    };

    return chat;
}

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor
{
    NSParameterAssert(descriptor);

    NSDictionary *mapping = @{
#warning check if we can sort with lastMessage (lastMessage.property?)
        NSStringFromSelector(@selector(lastMessage)) : NSStringFromSelector(@selector(lastMessage)),
        NSStringFromSelector(@selector(enteredText)) : NSStringFromSelector(@selector(enteredText)),
        NSStringFromSelector(@selector(lastReadDate)) : NSStringFromSelector(@selector(lastReadDateInterval)),
    };

    NSString *rlmProperty = mapping[descriptor.property];

    if (! rlmProperty) {
        return nil;
    }

    return [RLMSortDescriptor sortDescriptorWithProperty:rlmProperty ascending:descriptor.ascending];
}

@end
