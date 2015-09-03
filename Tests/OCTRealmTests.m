//
//  OCTRealmTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

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

    self.realmManager = [[OCTRealmManager alloc] initWithDatabasePath:@"path"];
    self.realmManager = OCMPartialMock(self.realmManager);
}

- (void)tearDown
{
    [self.realmMock stopMocking];
    self.realmMock = nil;

    self.realmManager = nil;
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
