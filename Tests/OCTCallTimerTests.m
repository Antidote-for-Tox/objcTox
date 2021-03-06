// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>

#import "OCTCallTimer.h"
#import "OCTCall.h"
#import "OCTRealmTests.h"

@interface OCTCallTimer (Tests)

@property (strong, nonatomic) dispatch_source_t timer;
@property (weak, nonatomic) OCTRealmManager *realmManager;

@end
@interface OCTCallTimerTests : OCTRealmTests

@property (strong, nonatomic) OCTCallTimer *callTimer;

@end

@implementation OCTCallTimerTests

- (void)setUp
{
    [super setUp];

    self.callTimer = [[OCTCallTimer alloc] initWithRealmManager:self.realmManager];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNil(self.callTimer.timer);
    XCTAssertNotNil(self.callTimer.realmManager);
}

- (void)testStartTimer
{
    OCTFriend *friend = [self createFriendWithFriendNumber:9];

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];
    OCTCall *call = [self.realmManager createCallWithChat:chat status:OCTCallStatusActive];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Test Timer"];

    [self.callTimer startTimerForCall:call];

    dispatch_time_t delayTime =  dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC);

    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        if (call.callDuration > 1) {
            [expectation fulfill];
        }
    });

    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        [self.callTimer stopTimer];
    }];
}

@end
