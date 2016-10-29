// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTSubmanagerDNSImpl.h"
#import "OCTToxDNS.h"
#import "OCTPredefined.h"
#import "OCTManagerConstants.h"
#import "OCTToxDNS3Object.h"

DNSServiceErrorType (*_DNSServiceQueryRecord)(
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context);
DNSServiceErrorType (*_DNSServiceProcessResult)(DNSServiceRef sdRef);
void (*_DNSServiceRefDeallocate)(DNSServiceRef sdRef);


static const uint16_t kMaxDNS3StringLength = 255;

static void dnsQueryFunction(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex,
                             DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype,
                             uint16_t rrclass, uint16_t rdlen, const void *rdata, uint32_t ttl, void *context);

@interface OCTSubmanagerDNSImpl ()

/**
 * Dictionary contains:
 * - server domain as key.
 * - OCTToxDNS objects as value.
 */
@property (strong, nonatomic) NSMutableDictionary *dns3Dictionary;

@end

@implementation OCTSubmanagerDNSImpl
@synthesize dataSource = _dataSource;

#pragma mark -  Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    [self setupCFunctions];

    return self;
}

#pragma mark -  Properties

- (NSMutableDictionary *)dns3Dictionary
{
    if (! _dns3Dictionary) {
        _dns3Dictionary = [NSMutableDictionary new];
    }

    return _dns3Dictionary;
}

#pragma mark -  Public

- (void)addTox3Server:(nonnull NSString *)domain publicKey:(nonnull NSString *)publicKey
{
    NSParameterAssert(domain);
    NSParameterAssert(publicKey);

    self.dns3Dictionary[domain] = [[OCTToxDNS alloc] initWithServerPublicKey:publicKey];
}

- (void)addPredefinedTox3Servers
{
    for (NSArray *serverArray in [OCTPredefined tox3Servers]) {
        [self addTox3Server:serverArray[0] publicKey:serverArray[1]];
    }
}

- (void)tox3DiscoveryForString:(nonnull NSString *)string
                       success:(nullable void (^)(NSString *__nonnull toxId))successBlock
                       failure:(nullable void (^)(NSError *__nonnull error))failureBlock
{
    NSParameterAssert(string);

    NSString *name;
    NSString *domain;

    if (! [self getName:&name andDomain:&domain fromString:string failure:failureBlock]) {
        return;
    }

    OCTToxDNS *dns = self.dns3Dictionary[domain];

    if (! dns) {
        [self callFailureBlock:failureBlock withCode:OCTDNSErrorNoPublicKey];
        return;
    }

    OCTToxDNS3Object *dns3Object = [dns generateDNS3StringForName:name maxStringLength:kMaxDNS3StringLength];
    NSString *fullname = [NSString stringWithFormat:@"_%@._tox.%@", dns3Object.generatedString, domain];

    __weak OCTSubmanagerDNSImpl *weakSelf = self;

    [self makeDNSQueryWithFullname:fullname callback:^(DNSServiceErrorType errorCode, NSData *data) {
        __strong OCTSubmanagerDNSImpl *strongSelf = weakSelf;

        if ((errorCode != kDNSServiceErr_NoError) || ! data) {
            [strongSelf callFailureBlock:failureBlock withCode:OCTDNSErrorDNSQueryError];
            return;
        }

        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSString *encrypted = [strongSelf stringFromDNSResult:result forKey:@"id"];
        NSString *decrypted = [dns decryptDNS3Text:encrypted forObject:dns3Object];

        if (decrypted) {
            if (successBlock) {
                successBlock(decrypted);
            }
        }
        else {
            [strongSelf callFailureBlock:failureBlock withCode:OCTDNSErrorDNSQueryError];
        }

    } failure:failureBlock];
}

- (void)tox1DiscoveryForString:(nonnull NSString *)string
                       success:(nullable void (^)(NSString *__nonnull toxId))successBlock
                       failure:(nullable void (^)(NSError *__nonnull error))failureBlock
{
    NSParameterAssert(string);

    NSString *name;
    NSString *domain;

    if (! [self getName:&name andDomain:&domain fromString:string failure:failureBlock]) {
        return;
    }

    __weak OCTSubmanagerDNSImpl *weakSelf = self;
    NSString *fullname = [NSString stringWithFormat:@"%@._tox.%@.", name, domain];

    [self makeDNSQueryWithFullname:fullname callback:^(DNSServiceErrorType errorCode, NSData *data) {
        __strong OCTSubmanagerDNSImpl *strongSelf = weakSelf;

        if ((errorCode != kDNSServiceErr_NoError) || ! data) {
            [strongSelf callFailureBlock:failureBlock withCode:OCTDNSErrorDNSQueryError];
            return;
        }

        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        result = [strongSelf stringFromDNSResult:result forKey:@"id"];

        if (result) {
            if (successBlock) {
                successBlock(result);
            }
        }
        else {
            [strongSelf callFailureBlock:failureBlock withCode:OCTDNSErrorDNSQueryError];
        }

    } failure:failureBlock];
}

#pragma mark -  Private

- (void)setupCFunctions
{
    _DNSServiceQueryRecord = DNSServiceQueryRecord;
    _DNSServiceProcessResult = DNSServiceProcessResult;
    _DNSServiceRefDeallocate = DNSServiceRefDeallocate;
}

- (void)callFailureBlock:(void (^)(NSError *error))failureBlock withCode:(OCTDNSError)code
{
    if (! failureBlock) {
        return;
    }

    NSString *failureReason = nil;

    switch (code) {
        case OCTDNSErrorWrongString:
            failureReason = @"Given string for DNS discovery is wrong";
            break;
        case OCTDNSErrorNoPublicKey:
            failureReason = @"No public key found for domain";
            break;
        case OCTDNSErrorDNSQueryError:
            failureReason = @"Error occured during DNS discovery";
    }

    failureBlock([NSError errorWithDomain:kOCTToxErrorDomain code:code userInfo:@{
                      NSLocalizedDescriptionKey : @"DNS discovery failure",
                      NSLocalizedFailureReasonErrorKey : failureReason,
                  }]);
}

- (BOOL)getName:(NSString **)name
      andDomain:(NSString **)domain
     fromString:(NSString *)string
        failure:(nullable void (^)(NSError *__nonnull error))failureBlock
{
    NSArray *array = [string componentsSeparatedByString:@"@"];

    NSString *theName = nil;
    NSString *theDomain = nil;

    if (array.count == 2) {
        theName = array[0];
        theDomain = array[1];
    }

    if (theName.length && theDomain.length) {
        *name = theName;
        *domain = theDomain;
        return YES;
    }

    [self callFailureBlock:failureBlock withCode:OCTDNSErrorWrongString];
    return NO;
}

- (void)makeDNSQueryWithFullname:(NSString *)fullname
                        callback:(OCTDNSQueryCallback)callback
                         failure:(void (^)(NSError *))failureBlock
{
    NSParameterAssert(fullname);

    DNSServiceRef serviceRef;
    DNSServiceErrorType dnsError = _DNSServiceQueryRecord(
        &serviceRef,
        0,
        0,
        [fullname cStringUsingEncoding:NSUTF8StringEncoding],
        kDNSServiceType_TXT,
        kDNSServiceClass_IN,
        dnsQueryFunction,
        (__bridge void *)(callback));

    if (dnsError != kDNSServiceErr_NoError) {
        [self callFailureBlock:failureBlock withCode:OCTDNSErrorDNSQueryError];
        goto clear;
    }

    dnsError = _DNSServiceProcessResult(serviceRef);

    if (dnsError != kDNSServiceErr_NoError) {
        [self callFailureBlock:failureBlock withCode:OCTDNSErrorDNSQueryError];
        goto clear;
    }

    clear:
    _DNSServiceRefDeallocate(serviceRef);
}

- (NSString *)stringFromDNSResult:(NSString *)result forKey:(NSString *)key
{
    // result has following format
    // av=tox3;id=nwlktjadoakxxr5yp4ucaawqn5ii15p2fgijdjmkreatorpkwg0p3xiynbaudmdbs4von15a21d1gqtzjr15isd

    for (NSString *component in [result componentsSeparatedByString:@";"]) {
        NSArray *array = [component componentsSeparatedByString:@"="];

        if (array.count == 2) {
            if ([array[0] isEqualToString:key]) {
                return array[1];
            }
        }
    }

    return nil;
}

@end

static void dnsQueryFunction(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex,
                             DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype,
                             uint16_t rrclass, uint16_t rdlen, const void *rdata, uint32_t ttl, void *context)
{
    OCTDNSQueryCallback callback = (__bridge OCTDNSQueryCallback)(context);

    if (errorCode == kDNSServiceErr_NoError) {
        NSData *data = (rdlen > 0) ? ([NSData dataWithBytes:rdata length:rdlen]) : nil;
        callback(errorCode, data);
    }
    else {
        callback(errorCode, nil);
    }
}
