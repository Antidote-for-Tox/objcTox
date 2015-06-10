//
//  OCTConverterFriend.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 03.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterFriend.h"
#import "OCTDBFriend.h"
#import "OCTFriend+Private.h"

@implementation OCTConverterFriend

#pragma mark -  Public

- (OCTFriend *)friendFromFriendNumber:(OCTToxFriendNumber)friendNumber
{
    NSParameterAssert(self.dataSource);

    OCTTox *tox = [self.dataSource converterFriendGetTox:self];
    OCTDBManager *dbManager = [self.dataSource converterFriendGetDBManager:self];

    if (! [tox friendExistsWithFriendNumber:friendNumber]) {
        return nil;
    }

    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = friendNumber;
    friend.publicKey = [tox publicKeyFromFriendNumber:friendNumber error:nil];
    friend.name = [tox friendNameWithFriendNumber:friendNumber error:nil];
    friend.statusMessage = [tox friendStatusMessageWithFriendNumber:friendNumber error:nil];
    friend.status = [tox friendStatusWithFriendNumber:friendNumber error:nil];
    friend.connectionStatus = [tox friendConnectionStatusWithFriendNumber:friendNumber error:nil];
    friend.lastSeenOnline = [tox friendGetLastOnlineWithFriendNumber:friendNumber error:nil];
    friend.isTyping = [tox isFriendTypingWithFriendNumber:friendNumber error:nil];

    OCTDBFriend *dbFriend = [dbManager getOrCreateFriendWithFriendNumber:friendNumber];

    friend.nickname = dbFriend.nickname ?: friend.name ?: friend.publicKey;

    friend.nickname = dbFriend.nickname.length ? dbFriend.nickname :
                      friend.name.length ? friend.name :
                      friend.publicKey;

    __weak OCTConverterFriend *weakSelf = self;
    friend.nicknameUpdateBlock = ^(NSString *nickname) {
        [weakSelf.dataSource converterFriend:weakSelf updateDBFriendWithBlock:^{
            dbFriend.nickname = nickname;
        }];
    };

    return friend;
}

#pragma mark -  OCTConverterProtocol

- (NSString *)objectClassName
{
    return NSStringFromClass([OCTFriend class]);
}

- (NSString *)dbObjectClassName
{
    return NSStringFromClass([OCTDBFriend class]);
}

- (id)objectFromRLMObject:(OCTDBFriend *)dbFriend
{
    NSParameterAssert(dbFriend);

    OCTToxFriendNumber friendNumber = (OCTToxFriendNumber)dbFriend.friendNumber;

    return [self friendFromFriendNumber:friendNumber];
}

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor
{
    NSParameterAssert(descriptor);

    NSDictionary *mapping = @{
        NSStringFromSelector(@selector(friendNumber)) : NSStringFromSelector(@selector(friendNumber)),
        NSStringFromSelector(@selector(nickname)) : NSStringFromSelector(@selector(nickname)),
    };

    NSString *rlmProperty = mapping[descriptor.property];

    if (! rlmProperty) {
        return nil;
    }

    return [RLMSortDescriptor sortDescriptorWithProperty:rlmProperty ascending:descriptor.ascending];
}

@end
