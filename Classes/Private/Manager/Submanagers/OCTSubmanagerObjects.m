//
//  OCTSubmanagerObjects.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerObjects+Private.h"
#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"

@interface OCTSubmanagerObjects ()

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@end

@implementation OCTSubmanagerObjects

#pragma mark -  Public

- (RBQFetchRequest *)fetchRequestForType:(OCTFetchRequestType)type withPredicate:(NSPredicate *)predicate
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];
    return [manager fetchRequestForClass:[self classForFetchRequestType:type] withPredicate:predicate];
}

- (OCTObject *)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier forType:(OCTFetchRequestType)type
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];
    return [manager objectWithUniqueIdentifier:uniqueIdentifier class:[self classForFetchRequestType:type]];
}

#pragma mark -  Friends

- (void)changeFriend:(OCTFriend *)friend nickname:(NSString *)nickname
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];

    [manager updateObject:friend withBlock:^(OCTFriend *theFriend) {
        theFriend.nickname = nickname;
    }];
}

#pragma mark -  Chats

- (void)changeChat:(OCTChat *)chat enteredText:(NSString *)enteredText
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];

    [manager updateObject:chat withBlock:^(OCTChat *theChat) {
        theChat.enteredText = enteredText;
    }];
}

- (void)changeChat:(OCTChat *)chat lastReadDateInterval:(NSTimeInterval)lastReadDateInterval
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];

    [manager updateObject:chat withBlock:^(OCTChat *theChat) {
        theChat.lastReadDateInterval = lastReadDateInterval;
    }];
}

#pragma mark -  Private

- (Class)classForFetchRequestType:(OCTFetchRequestType)type
{
    switch (type) {
        case OCTFetchRequestTypeFriend:
            return [OCTFriend class];
        case OCTFetchRequestTypeFriendRequest:
            return [OCTFriendRequest class];
        case OCTFetchRequestTypeChat:
            return [OCTChat class];
        case OCTFetchRequestTypeMessageAbstract:
            return [OCTMessageAbstract class];
    }
}

@end
