// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <OCMock/OCMock.h>

#import "OCTRealmTests.h"

@interface OCTRealmTests ()

@property (strong, nonatomic) id realmMock;

@end

@implementation OCTRealmTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.inMemoryIdentifier = @"OCTRealmTests";

    RLMRealm *realRealm = [RLMRealm realmWithConfiguration:configuration error:nil];

    self.realmMock = OCMClassMock([RLMRealm class]);
    OCMStub([self.realmMock realmWithConfiguration:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(realRealm);

    NSURL *fileURL = [NSURL fileURLWithPath:@"/some/realm/path"];
    self.realmManager = [[OCTRealmManager alloc] initWithDatabaseFileURL:fileURL encryptionKey:nil];
    self.realmManager = OCMPartialMock(self.realmManager);
}

- (void)tearDown
{
    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm deleteAllObjects];
    [self.realmManager.realm commitWriteTransaction];

    [(id)self.realmManager stopMocking];
    self.realmManager = nil;

    [self.realmMock stopMocking];
    self.realmMock = nil;

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (OCTFriend *)createFriend
{
    OCTFriend *friend = [OCTFriend new];
    friend.nickname = @"";
    friend.publicKey = @"";

    return friend;
}

@end
