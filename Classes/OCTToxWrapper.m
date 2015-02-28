//
//  OCTToxWrapper.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 28.02.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTToxWrapper.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

NSString *const kOCTToxWrapperErrorDomain = @"OCTToxWrapper Error Domain";

const NSUInteger kOCTToxAddressLength = 2 * TOX_FRIEND_ADDRESS_SIZE;
const NSUInteger kOCTToxPublicKeyLength = 2 * TOX_PUBLIC_KEY_SIZE;

@implementation OCTToxWrapper

#pragma mark -  Tox methods

+ (NSString *)toxGetAddress:(const Tox *)tox
{
    NSParameterAssert(tox);

    const NSUInteger length = TOX_FRIEND_ADDRESS_SIZE;
    uint8_t *cAddress = malloc(length);

    tox_get_address(tox, cAddress);

    if (! cAddress) {
        return nil;
    }

    NSString *address = [self binToHexString:cAddress length:length];

    free(cAddress);

    DDLogVerbose(@"OCTToxWrapper: get address: %@", address);

    return address;
}

+ (int32_t)toxAddFriend:(Tox *)tox address:(NSString *)address message:(NSString *)message error:(NSError **)error
{
    NSParameterAssert(tox);
    NSParameterAssert(address);
    NSParameterAssert(message);
    NSAssert(address.length == kOCTToxAddressLength, @"Address must be kOCTToxAddressLength length");

    DDLogVerbose(@"OCTToxWrapper: add friend with address %@, message %@", address, message);

    if (! [self checkFriendRequestMessageLength:message]) {
        message = [self cropFriendRequestMessageToFit:message];
    }

    uint8_t *cAddress = [self hexStringToBin:address];
    const char *cMessage = [message cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int32_t result = tox_add_friend(tox, cAddress, (const uint8_t *)cMessage, length);

    free(cAddress);

    if (result > -1) {
        DDLogInfo(@"OCTToxWrapper: add friend: success with friend number %d", result);
        return result;
    }

    OCTToxWrapperAddFriendError code = OCTToxWrapperAddFriendErrorUnknown;
    NSString *description = @"Cannot add friend";
    NSString *failureReason = nil;

    switch(result) {
        case TOX_FAERR_TOOLONG:
            code = OCTToxWrapperAddFriendErrorMessageIsTooLong;
            failureReason = @"The message is too long";
            break;
        case TOX_FAERR_NOMESSAGE:
            code = OCTToxWrapperAddFriendErrorNoMessage;
            failureReason = @"No message specified";
            break;
        case TOX_FAERR_OWNKEY:
            code = OCTToxWrapperAddFriendErrorOwnAddress;
            failureReason = @"Cannot add own address";
            break;
        case TOX_FAERR_ALREADYSENT:
            code = OCTToxWrapperAddFriendErrorAlreadySent;
            failureReason = @"The request was already sent";
            break;
        case TOX_FAERR_UNKNOWN:
            code = OCTToxWrapperAddFriendErrorUnknown;
            failureReason = @"Unknown error";
            break;
        case TOX_FAERR_BADCHECKSUM:
            code = OCTToxWrapperAddFriendErrorBadChecksum;
            failureReason = @"Bad checksum";
            break;
        case TOX_FAERR_SETNEWNOSPAM:
            code = OCTToxWrapperAddFriendErrorSetNewNoSpam;
            failureReason = @"The no spam value is outdated";
            break;
        case TOX_FAERR_NOMEM:
            code = OCTToxWrapperAddFriendErrorNoMem;
            failureReason = nil;
            break;
        default:
            break;
    };

    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    if (description) {
        userInfo[NSLocalizedDescriptionKey] = description;
    }

    if (failureReason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;
    }

    NSError *theError = [NSError errorWithDomain:kOCTToxWrapperErrorDomain code:code userInfo:userInfo];
    if (error) {
        *error = theError;
    }

    DDLogWarn(@"OCTToxWrapper: add friend: failure with error %@", theError);

    return -1;
}

+ (int32_t)toxAddFriendWithNoRequest:(Tox *)tox publicKey:(NSString *)publicKey
{
    NSParameterAssert(tox);
    NSParameterAssert(publicKey);
    NSAssert(publicKey.length == kOCTToxPublicKeyLength, @"Public key must be kOCTToxPublicKeyLength length");

    DDLogVerbose(@"OCTToxWrapper: add friend with no request and public key %@", publicKey);

    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int32_t result = tox_add_friend_norequest(tox, cPublicKey);

    free(cPublicKey);

    if (result < 0) {
        DDLogWarn(@"OCTToxWrapper: add friend with no request failed with error");
    }
    else {
        DDLogInfo(@"OCTToxWrapper: add friend with no request: success with friend number %d", result);
    }

    return result;
}

#pragma mark -  Helper methods

+ (BOOL)checkFriendRequestMessageLength:(NSString *)message
{
    return [self checkMessage:message withMaxBytesLength:TOX_MAX_FRIENDREQUEST_LENGTH];
}

+ (NSString *)cropFriendRequestMessageToFit:(NSString *)message
{
    return [self cropMessage:message withMaxBytesLength:TOX_MAX_FRIENDREQUEST_LENGTH];
}

#pragma mark -  Private

+ (NSString *)binToHexString:(uint8_t *)bin length:(NSUInteger)length
{
    NSMutableString *string = [NSMutableString stringWithCapacity:length * 2];

    for (NSUInteger idx = 0; idx < length; ++idx) {
        [string appendFormat:@"%02X", bin[idx]];
    }

    return [string copy];
}

// You are responsible for freeing the return value!
+ (uint8_t *)hexStringToBin:(NSString *)string
{
    // byte is represented by exactly 2 hex digits, so lenth of binary string
    // is half of that of the hex one. only hex string with even length
    // valid. the more proper implementation would be to check if strlen(hex_string)
    // is odd and return error code if it is. we assume strlen is even. if it's not
    // then the last byte just won't be written in 'ret'.

    char *hex_string = (char *)string.UTF8String;
    size_t i, len = strlen(hex_string) / 2;
    uint8_t *ret = malloc(len);
    char *pos = hex_string;

    for (i = 0; i < len; ++i, pos += 2) {
        sscanf(pos, "%2hhx", &ret[i]);
    }

    return ret;
}

+ (BOOL)checkMessage:(NSString *)message withMaxBytesLength:(NSUInteger)maxLength
{
    NSUInteger length = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    return length <= maxLength;
}

+ (NSString *)cropMessage:(NSString *)message withMaxBytesLength:(NSUInteger)maxLength
{
    NSUInteger length = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    if (length <= maxLength) {
        return message;
    }

    return [self substringFromString:message toByteLength:maxLength usingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)substringFromString:(NSString *)string
                      toByteLength:(NSUInteger)length
                     usingEncoding:(NSStringEncoding)encoding
{
    if (! length) {
        return @"";
    }

    while ([string lengthOfBytesUsingEncoding:encoding] > length) {
        NSUInteger newLength = string.length - 1;

        if (! newLength) {
            return @"";
        }

        string = [string substringToIndex:newLength];
    }

    return string;
}

@end
