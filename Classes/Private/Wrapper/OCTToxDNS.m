// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTToxDNS+Private.h"
#import "OCTToxConstants.h"
#import "OCTTox+Private.h"
#import "OCTToxDNS3Object.h"

void *(*_tox_dns3_new)(uint8_t *server_public_key);
void (*_tox_dns3_kill)(void *dns3_object);
int (*_tox_generate_dns3_string)(void *dns3_object, uint8_t *string, uint16_t string_max_len, uint32_t *request_id,
                                 uint8_t *name, uint8_t name_len);
int (*_tox_decrypt_dns3_TXT)(void *dns3_object, uint8_t *tox_id, uint8_t *id_record, uint32_t id_record_len,
                             uint32_t request_id);

const NSUInteger kOCTToxDNSMaxRecommendedNameLength = TOXDNS_MAX_RECOMMENDED_NAME_LENGTH;

@interface OCTToxDNS ()

@property (assign, nonatomic) void *dns3;

@end

@implementation OCTToxDNS

#pragma mark -  Lifecycle

- (instancetype)initWithServerPublicKey:(NSString *)serverPublicKey
{
    NSAssert(serverPublicKey.length == kOCTToxPublicKeyLength, @"serverPublicKey must be kOCTToxPublicKeyLength");

    self = [super init];

    if (! self) {
        return nil;
    }

    [self setupCFunctions];

    uint8_t *cAddress = [OCTTox hexStringToBin:serverPublicKey];
    void *dns3 = _tox_dns3_new(cAddress);
    free(cAddress);

    if (! dns3) {
        return nil;
    }

    _dns3 = dns3;

    return self;
}

- (void)dealloc
{
    _tox_dns3_kill(_dns3);
}

#pragma mark -  Public

- (OCTToxDNS3Object *)generateDNS3StringForName:(NSString *)name maxStringLength:(uint16_t)maxStringLength
{
    NSAssert(maxStringLength > 0, @"maxStringLength should be > 0");

    uint8_t *cString = malloc(maxStringLength);
    OCTToxDNSRequestId requestId;

    uint8_t *cName = (uint8_t *)[name cStringUsingEncoding:NSUTF8StringEncoding];
    uint8_t cNameLength = (uint8_t)[name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int cStringLength = _tox_generate_dns3_string(self.dns3, cString, maxStringLength, &requestId, cName, cNameLength);

    if (cStringLength == -1) {
        return nil;
    }

    OCTToxDNS3Object *object = [OCTToxDNS3Object new];
    object.generatedString = [[NSString alloc] initWithBytes:cString length:cStringLength encoding:NSUTF8StringEncoding];
    object.name = name;
    object.requestId = requestId;

    free(cString);

    return object;
}

- (NSString *)decryptDNS3Text:(NSString *)text forObject:(OCTToxDNS3Object *)object
{
    const uint8_t cToxIdLength = TOX_ADDRESS_SIZE;
    uint8_t *cToxId = malloc(cToxIdLength);

    uint8_t *cText = (uint8_t *)[text cStringUsingEncoding:NSUTF8StringEncoding];
    uint8_t cTextLength = (uint8_t)[text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int result = _tox_decrypt_dns3_TXT(self.dns3, cToxId, cText, cTextLength, object.requestId);

    if (result == -1) {
        return nil;
    }

    NSString *toxId = [OCTTox binToHexString:cToxId length:cToxIdLength];


    return toxId;
}

#pragma mark -  Private

- (void)setupCFunctions
{
    _tox_dns3_new = tox_dns3_new;
    _tox_dns3_kill = tox_dns3_kill;
    _tox_generate_dns3_string = tox_generate_dns3_string;
    _tox_decrypt_dns3_TXT = tox_decrypt_dns3_TXT;
}

@end
