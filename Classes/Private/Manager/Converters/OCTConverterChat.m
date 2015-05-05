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

@implementation OCTConverterChat

#pragma mark -  OCTConverterProtocol

- (NSString *)objectClassName
{
    return NSStringFromClass([OCTChat class]);
}

- (NSObject *)objectFromRLMObject:(OCTDBChat *)db
{
    OCTChat *chat = [OCTChat new];

    NSMutableArray *friends = [NSMutableArray new];

    for (OCTDBFriend *dbFriend in db.friends) {
        OCTFriend *friend = (OCTFriend *)[self.converterFriend objectFromRLMObject:dbFriend];
        [friends addObject:friend];
    }

    chat.friends = [friends copy];
    chat.lastMessage = (OCTMessageAbstract *)[self.converterMessage objectFromRLMObject:db.lastMessage];
    chat.enteredText = db.enteredText;
    chat.lastReadDate = [NSDate dateWithTimeIntervalSince1970:db.lastReadDateInterval];

    chat.dbChat = db;
    // TODO
    // chat.dbManager = 

    return chat;
}

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor
{
    return nil;
}

@end
