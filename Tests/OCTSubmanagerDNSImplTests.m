// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTSubmanagerDNSImpl.h"
#import "OCTToxDNS.h"
#import "OCTToxDNS3Object.h"
#import "OCTManagerConstants.h"
#import "OCTToxConstants.h"

DNSServiceErrorType MockedDNSServiceQueryRecordSuccess (
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context);
DNSServiceErrorType MockedDNSServiceQueryRecordFailureCallback (
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context);
DNSServiceErrorType MockedDNSServiceQueryRecordFailureImmediately (
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context);
DNSServiceErrorType MockedDNSServiceProcessResult (DNSServiceRef sdRef);
void MockedDNSServiceRefDeallocate (DNSServiceRef sdRef);

typedef NS_ENUM(NSUInteger, MockedQueryType) {
    MockedQueryTypeSuccess,
    MockedQueryTypeFailureImmediately,
    MockedQueryTypeFailureCallback,
};

@interface OCTSubmanagerDNSImpl (Tests)
@property (strong, nonatomic) NSMutableDictionary *dns3Dictionary;
@end

@interface OCTSubmanagerDNSImplTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerDNSImpl *submanager;

@end

@implementation OCTSubmanagerDNSImplTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.submanager = [OCTSubmanagerDNSImpl new];
}

- (void)tearDown
{
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddTox3Server
{
    id toxDNS = OCMClassMock([OCTToxDNS class]);
    OCMStub([toxDNS alloc]).andReturn(toxDNS);
    OCMExpect([toxDNS initWithServerPublicKey:@"public"]).andReturn(toxDNS);

    [self.submanager addTox3Server:@"domain" publicKey:@"public"];

    XCTAssertEqual(toxDNS, self.submanager.dns3Dictionary[@"domain"]);

    OCMVerify(toxDNS);
    [toxDNS stopMocking];
}

- (void)testTox3DiscoveryWrongString
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];

    [self.submanager tox3DiscoveryForString:@"wrongstring" success:^(NSString *toxId) {
        XCTAssertTrue(NO, @"We shouldn't be here");

    } failure:^(NSError *error) {
        XCTAssertEqual(error.code, OCTDNSErrorWrongString);
        XCTAssertEqualObjects(error.domain, kOCTToxErrorDomain);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

- (void)testTox3DiscoveryNoPublicKey
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];

    [self.submanager tox3DiscoveryForString:@"some@domain.com" success:^(NSString *toxId) {
        XCTAssertTrue(NO, @"We shouldn't be here");

    } failure:^(NSError *error) {
        XCTAssertEqual(error.code, OCTDNSErrorNoPublicKey);
        XCTAssertEqualObjects(error.domain, kOCTToxErrorDomain);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

- (void)testTox3DiscoveryQueryErrorImmediately
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];
    [self mockDNSQueryWithSuccess:MockedQueryTypeFailureImmediately];

    id dns3Object = OCMClassMock([OCTToxDNS3Object class]);
    id dns = OCMClassMock([OCTToxDNS class]);
    OCMStub([dns generateDNS3StringForName:@"name" maxStringLength:7]).andReturn(dns3Object);

    self.submanager.dns3Dictionary = [NSMutableDictionary dictionaryWithObject:dns forKey:@"domain"];

    [self.submanager tox3DiscoveryForString:@"some@domain" success:^(NSString *toxId) {
        XCTAssertTrue(NO, @"We shouldn't be here");

    } failure:^(NSError *error) {
        XCTAssertEqual(error.code, OCTDNSErrorDNSQueryError);
        XCTAssertEqualObjects(error.domain, kOCTToxErrorDomain);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

- (void)testTox3DiscoveryQueryErrorCallback
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];
    [self mockDNSQueryWithSuccess:MockedQueryTypeFailureCallback];

    id dns3Object = OCMClassMock([OCTToxDNS3Object class]);
    id dns = OCMClassMock([OCTToxDNS class]);
    OCMStub([dns generateDNS3StringForName:@"name" maxStringLength:7]).andReturn(dns3Object);

    self.submanager.dns3Dictionary = [NSMutableDictionary dictionaryWithObject:dns forKey:@"domain"];

    [self.submanager tox3DiscoveryForString:@"some@domain" success:^(NSString *toxId) {
        XCTAssertTrue(NO, @"We shouldn't be here");

    } failure:^(NSError *error) {
        XCTAssertEqual(error.code, OCTDNSErrorDNSQueryError);
        XCTAssertEqualObjects(error.domain, kOCTToxErrorDomain);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

- (void)testTox3DiscoveryQuerySuccess
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];
    [self mockDNSQueryWithSuccess:MockedQueryTypeSuccess];

    id dns3Object = OCMClassMock([OCTToxDNS3Object class]);
    id dns = OCMClassMock([OCTToxDNS class]);
    OCMStub([dns generateDNS3StringForName:@"name" maxStringLength:255]).andReturn(dns3Object);
    OCMStub([dns decryptDNS3Text:@"success" forObject:[OCMArg any]]).andReturn(@"toxId");

    self.submanager.dns3Dictionary = [NSMutableDictionary dictionaryWithObject:dns forKey:@"domain"];

    [self.submanager tox3DiscoveryForString:@"some@domain" success:^(NSString *toxId) {
        XCTAssertEqualObjects(toxId, @"toxId");

        [expectation fulfill];

    } failure:^(NSError *error) {
        XCTAssertTrue(NO, @"We shouldn't be here");
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

- (void)testTox1DiscoveryQueryErrorImmediately
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];
    [self mockDNSQueryWithSuccess:MockedQueryTypeFailureImmediately];

    [self.submanager tox1DiscoveryForString:@"some@domain" success:^(NSString *toxId) {
        XCTAssertTrue(NO, @"We shouldn't be here");

    } failure:^(NSError *error) {
        XCTAssertEqual(error.code, OCTDNSErrorDNSQueryError);
        XCTAssertEqualObjects(error.domain, kOCTToxErrorDomain);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

- (void)testToxDiscoveryQueryErrorCallback
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];
    [self mockDNSQueryWithSuccess:MockedQueryTypeFailureCallback];

    [self.submanager tox1DiscoveryForString:@"some@domain" success:^(NSString *toxId) {
        XCTAssertTrue(NO, @"We shouldn't be here");

    } failure:^(NSError *error) {
        XCTAssertEqual(error.code, OCTDNSErrorDNSQueryError);
        XCTAssertEqualObjects(error.domain, kOCTToxErrorDomain);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

- (void)testTox1DiscoveryQuerySuccess
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"discovery"];
    [self mockDNSQueryWithSuccess:MockedQueryTypeSuccess];

    [self.submanager tox1DiscoveryForString:@"some@domain" success:^(NSString *toxId) {
        XCTAssertEqualObjects(toxId, @"success");

        [expectation fulfill];

    } failure:^(NSError *error) {
        XCTAssertTrue(NO, @"We shouldn't be here");
    }];

    [self waitForExpectationsWithTimeout:0.05 handler:nil];
}

#pragma mark -  Helper

- (void)mockDNSQueryWithSuccess:(MockedQueryType)type
{
    switch (type) {
        case MockedQueryTypeSuccess:
            _DNSServiceQueryRecord = MockedDNSServiceQueryRecordSuccess;
            break;
        case MockedQueryTypeFailureImmediately:
            _DNSServiceQueryRecord = MockedDNSServiceQueryRecordFailureImmediately;
            break;
        case MockedQueryTypeFailureCallback:
            _DNSServiceQueryRecord = MockedDNSServiceQueryRecordFailureCallback;
            break;
    }
    _DNSServiceProcessResult = MockedDNSServiceProcessResult;
    _DNSServiceRefDeallocate = MockedDNSServiceRefDeallocate;
}

@end

DNSServiceErrorType MockedDNSServiceQueryRecordSuccess (
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context)
{
    NSData *data = [@"v=tox3;id=success" dataUsingEncoding:NSUTF8StringEncoding];

    (*callBack)(NULL, 0, 0, kDNSServiceErr_NoError, 0, 0, 0, data.length, [data bytes], 0, context);
    return kDNSServiceErr_NoError;
}

DNSServiceErrorType MockedDNSServiceQueryRecordFailureCallback (
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context)
{
    (*callBack)(NULL, 0, 0, kDNSServiceErr_NoError + 1, 0, 0, 0, 0, 0, 0, context);
    return kDNSServiceErr_NoError;
}

DNSServiceErrorType MockedDNSServiceQueryRecordFailureImmediately (
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context)
{
    return kDNSServiceErr_NoError + 1;
}

DNSServiceErrorType MockedDNSServiceProcessResult (DNSServiceRef sdRef)
{
    return kDNSServiceErr_NoError;
}

void MockedDNSServiceRefDeallocate (DNSServiceRef sdRef)
{}
