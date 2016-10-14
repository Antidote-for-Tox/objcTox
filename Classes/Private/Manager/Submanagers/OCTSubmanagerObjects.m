// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTSubmanagerObjects+Private.h"
#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTChat.h"
#import "OCTCall.h"
#import "OCTMessageAbstract.h"
#import "OCTSettingsStorageObject.h"

@interface OCTSubmanagerObjects ()

@end

@implementation OCTSubmanagerObjects
@synthesize dataSource = _dataSource;

#pragma mark -  Public

- (void)setGenericSettingsData:(NSData *)data
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];

    [manager updateObject:manager.settingsStorage withBlock:^(OCTSettingsStorageObject *object) {
        object.genericSettingsData = data;
    }];
}

- (NSData *)genericSettingsData
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];
    return manager.settingsStorage.genericSettingsData;
}

- (RLMResults *)objectsForType:(OCTFetchRequestType)type predicate:(NSPredicate *)predicate
{
    OCTRealmManager *manager = [self.dataSource managerGetRealmManager];
    return [manager objectsWithClass:[self classForFetchRequestType:type] predicate:predicate];
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
        if (nickname.length) {
            theFriend.nickname = nickname;
        }
        else if (theFriend.name.length) {
            theFriend.nickname = theFriend.name;
        }
        else {
            theFriend.nickname = theFriend.publicKey;
        }
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
        case OCTFetchRequestTypeCall:
            return [OCTCall class];
        case OCTFetchRequestTypeMessageAbstract:
            return [OCTMessageAbstract class];
    }
}

@end
