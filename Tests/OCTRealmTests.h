// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTChat.h"

@interface OCTRealmManager (Tests)

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) RLMRealm *realm;

@end

@interface OCTRealmTests : XCTestCase

/**
 * Partially mocked realm manager with in memory realm, which is reset after each test.
 */
@property (strong, nonatomic) OCTRealmManager *realmManager;

- (OCTFriend *)createFriend;
- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber;

@end
