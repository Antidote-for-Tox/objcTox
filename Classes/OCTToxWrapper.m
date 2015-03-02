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

+ (Tox *)toxNewWithIPv6Enabled:(BOOL)IPv6Enabled UDPEnabled:(BOOL)UDPEnabled;
{
    return [self toxNewWithIPv6Enabled:IPv6Enabled
                            UDPEnabled:UDPEnabled
                             proxyType:OCTToxWrapperProxyTypeNone
                          proxyAddress:nil
                             proxyPort:0];
}

+ (Tox *)toxNewWithIPv6Enabled:(BOOL)IPv6Enabled
                    UDPEnabled:(BOOL)UDPEnabled
                     proxyType:(OCTToxWrapperProxyType)proxyType
                  proxyAddress:(NSString *)proxyAddress
                     proxyPort:(uint16_t)proxyPort
{
    Tox_Options options;

    options.ipv6enabled = IPv6Enabled ? 1 : 0;
    options.udp_disabled = UDPEnabled ? 0 : 1;

    switch(proxyType) {
        case OCTToxWrapperProxyTypeNone:
            options.proxy_type = TOX_PROXY_NONE;
            break;
        case OCTToxWrapperProxyTypeSocks5:
            options.proxy_type = TOX_PROXY_SOCKS5;
            break;
        case OCTToxWrapperProxyTypeHTTP:
            options.proxy_type = TOX_PROXY_HTTP;
            break;
    }

    if (proxyAddress) {
        const char *cAddress = proxyAddress.UTF8String;
        strcpy(options.proxy_address, cAddress);
    }
    options.proxy_port = proxyPort;

    return tox_new(&options);
}

+ (BOOL)toxBootstrapFromAddress:(Tox *)tox
                        address:(NSString *)address
                           port:(uint16_t)port
                      publicKey:(NSString *)publicKey
{
    NSParameterAssert(tox);
    NSParameterAssert(address);
    NSParameterAssert(publicKey);

    const char *cAddress = address.UTF8String;
    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int result = tox_bootstrap_from_address(tox, cAddress, port, cPublicKey);

    free(cPublicKey);

    return (result == 1);
}

+ (BOOL)toxAddTCPRelay:(Tox *)tox
                  address:(NSString *)address
                     port:(uint16_t)port
                publicKey:(NSString *)publicKey
{
    NSParameterAssert(tox);
    NSParameterAssert(address);
    NSParameterAssert(publicKey);

    const char *cAddress = address.UTF8String;
    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int result = tox_bootstrap_from_address(tox, cAddress, port, cPublicKey);

    free(cPublicKey);

    return (result == 1);
}

+ (BOOL)toxIsConnected:(const Tox *)tox
{
    NSParameterAssert(tox);

    int result = tox_isconnected(tox);

    return (result == 1);
}

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

    if (! [self checkLengthOfString:message withCheckType:OCTToxWrapperCheckLengthTypeFriendRequest]) {
        message = [self cropString:message toFitType:OCTToxWrapperCheckLengthTypeFriendRequest];
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

+ (int32_t)toxGetFriendNumber:(const Tox *)tox publicKey:(NSString *)publicKey
{
    NSParameterAssert(tox);
    NSParameterAssert(publicKey);
    NSAssert(publicKey.length == kOCTToxPublicKeyLength, @"Public key must be kOCTToxPublicKeyLength length");

    DDLogVerbose(@"OCTToxWrapper: get friend number with public key %@", publicKey);

    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int32_t result = tox_get_friend_number(tox, cPublicKey);

    free(cPublicKey);

    if (result < 0) {
        DDLogWarn(@"OCTToxWrapper: get friend number with public key failed with error: no such friend");
    }
    else {
        DDLogInfo(@"OCTToxWrapper: get friend number with public key success with friend number %d", result);
    }

    return result;
}

+ (NSString *)toxGetPublicKey:(const Tox *)tox fromFriendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    DDLogVerbose(@"OCTToxWrapper: get public key from friend number %d", friendNumber);

    uint8_t *cPublicKey = malloc(TOX_CLIENT_ID_SIZE);
    int result = tox_get_client_id(tox, friendNumber, cPublicKey);

    NSString *publicKey = nil;

    if (result == 0) {
        publicKey = [self binToHexString:cPublicKey length:TOX_CLIENT_ID_SIZE];
        free(cPublicKey);
    }

    return publicKey;
}

+ (BOOL)toxDeleteFriend:(Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    int result = tox_del_friend(tox, friendNumber);

    return (result == 0);
}

+ (OCTToxWrapperConnectionStatus)toxGetFriendConnectionStatus:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    int result = tox_get_friend_connection_status(tox, friendNumber);

    switch(result) {
        case 1:
            return OCTToxWrapperConnectionStatusOnline;
        case 0:
            return OCTToxWrapperConnectionStatusOffline;
        case -1:
        default:
            return OCTToxWrapperConnectionStatusUnknown;
    }
}

+ (BOOL)toxFriendExists:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    int result = tox_friend_exists(tox, friendNumber);

    return (result == 1);
}

+ (uint32_t)toxSendMessage:(Tox *)tox friendNumber:(int32_t)friendNumber message:(NSString *)message
{
    NSParameterAssert(tox);
    NSParameterAssert(message);

    return [self toxSendMessageOrAction:tox friendNumber:friendNumber messageOrAction:message isMessage:YES];
}

+ (uint32_t)toxSendAction:(Tox *)tox friendNumber:(int32_t)friendNumber action:(NSString *)action
{
    NSParameterAssert(tox);
    NSParameterAssert(action);

    return [self toxSendMessageOrAction:tox friendNumber:friendNumber messageOrAction:action isMessage:NO];
}

+ (BOOL)toxSetName:(Tox *)tox name:(NSString *)name
{
    NSParameterAssert(tox);
    NSParameterAssert(name);

    const char *cName = [name cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int result = tox_set_name(tox, (const uint8_t *)cName, length);

    return (result == 0);
}

+ (NSString *)toxGetSelfName:(const Tox *)tox
{
    NSParameterAssert(tox);

    uint8_t *cName = malloc(TOX_MAX_NAME_LENGTH);
    uint16_t length = tox_get_self_name(tox, cName);

    NSString *name = nil;

    if (length) {
        name = [[NSString alloc] initWithBytes:cName length:length encoding:NSUTF8StringEncoding];

        free(cName);
    }

    return name;
}

+ (NSString *)toxGetFriendName:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    uint8_t *cName = malloc(TOX_MAX_NAME_LENGTH);
    uint16_t length = tox_get_name(tox, friendNumber, cName);

    NSString *name = nil;

    if (length) {
        name = [[NSString alloc] initWithBytes:cName length:length encoding:NSUTF8StringEncoding];

        free(cName);
    }

    return name;
}

+ (BOOL)toxSetStatusMessage:(Tox *)tox statusMessage:(NSString *)statusMessage
{
    NSParameterAssert(tox);
    NSParameterAssert(statusMessage);

    if (! [self checkLengthOfString:statusMessage withCheckType:OCTToxWrapperCheckLengthTypeStatusMessage]) {
        statusMessage = [self cropString:statusMessage toFitType:OCTToxWrapperCheckLengthTypeStatusMessage];
    }

    const char *cStatusMessage = [statusMessage cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [statusMessage lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int result = tox_set_status_message(tox, (const uint8_t *)cStatusMessage, length);

    return (result == 0);
}

+ (BOOL)toxSetUserStatus:(Tox *)tox status:(OCTToxWrapperUserStatus)status
{
    NSParameterAssert(tox);

    uint8_t cStatus = TOX_USERSTATUS_NONE;

    switch(status) {
        case OCTToxWrapperUserStatusNone:
            cStatus = TOX_USERSTATUS_NONE;
        case OCTToxWrapperUserStatusAway:
            cStatus = TOX_USERSTATUS_AWAY;
        case OCTToxWrapperUserStatusBusy:
            cStatus = TOX_USERSTATUS_BUSY;
        case OCTToxWrapperUserStatusInvalid:
            cStatus = TOX_USERSTATUS_INVALID;
            break;
    }

    int result = tox_set_user_status(tox, cStatus);

    return (result == 0);
}

+ (NSString *)toxGetFriendStatusMessage:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    int length = tox_get_status_message_size(tox, friendNumber);

    if (length <= 0) {
        return nil;
    }

    uint8_t *cBuffer = malloc(length);

    tox_get_status_message(tox, friendNumber, cBuffer, length);

    NSString *message = [[NSString alloc] initWithBytes:cBuffer length:length encoding:NSUTF8StringEncoding];
    free(cBuffer);

    return message;
}

+ (NSString *)toxGetSelfStatusMessage:(const Tox *)tox
{
    NSParameterAssert(tox);

    int length = tox_get_self_status_message_size(tox);

    if (length <= 0) {
        return nil;
    }

    uint8_t *cBuffer = malloc(length);

    tox_get_self_status_message(tox, cBuffer, length);

    NSString *message = [[NSString alloc] initWithBytes:cBuffer length:length encoding:NSUTF8StringEncoding];
    free(cBuffer);

    return message;
}

+ (NSDate *)toxGetLastOnline:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    uint64_t timestamp = tox_get_last_online(tox, friendNumber);

    if (! timestamp) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

+ (BOOL)toxSetUserIsTyping:(Tox *)tox friendNumber:(int32_t)friendNumber isTyping:(BOOL)isTyping
{
    NSParameterAssert(tox);

    uint8_t cIsTyping = isTyping ? 1 : 0;

    int result = tox_set_user_is_typing(tox, friendNumber, cIsTyping);

    return (result == 0);
}

+ (BOOL)toxGetIsFriendTyping:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    uint8_t cIsTyping = tox_get_is_typing(tox, friendNumber);

    return (cIsTyping == 1);
}

+ (NSUInteger)toxCountFriendList:(const Tox *)tox
{
    NSParameterAssert(tox);

    return tox_count_friendlist(tox);
}

+ (NSUInteger)toxGetNumberOnlineFriends:(const Tox *)tox
{
    NSParameterAssert(tox);

    return tox_get_num_online_friends(tox);
}

+ (NSArray *)toxGetFriendList:(const Tox *)tox
{
    NSParameterAssert(tox);

    uint32_t count = tox_count_friendlist(tox);

    if (! count) {
        return @[];
    }

    uint32_t listSize = count * sizeof(int32_t);
    int32_t *cList = malloc(listSize);

    tox_get_friendlist(tox, cList, listSize);

    NSMutableArray *list = [NSMutableArray new];

    for (NSUInteger index = 0; index < count; index++) {
        int32_t friendId = cList[index];
        [list addObject:@(friendId)];
    }

    free(cList);

    return [list copy];
}

+ (BOOL)toxSetAvatar:(Tox *)tox data:(NSData *)data
{
    NSParameterAssert(tox);
    NSParameterAssert(data);

    if (data.length > [self maximumDataLengthForType:OCTToxWrapperDataLengthTypeAvatar]) {
        return NO;
    }

    const uint8_t *bytes = [data bytes];

    int result = tox_set_avatar(tox, TOX_AVATAR_FORMAT_PNG, bytes, (uint32_t)data.length);

    return (result == 0);
}

+ (BOOL)toxUnsetAvatar:(Tox *)tox
{
    NSParameterAssert(tox);

    int result = tox_unset_avatar(tox);

    return (result == 0);
}

+ (NSData *)toxHash:(NSData *)data
{
    uint8_t *cHash = malloc(TOX_HASH_LENGTH);
    const uint8_t *cData = [data bytes];

    int result = tox_hash(cHash, cData, (uint32_t)data.length);

    if (result == -1) {
        return nil;
    }

    NSData *hash = [NSData dataWithBytes:cHash length:TOX_HASH_LENGTH];
    free(cHash);

    return hash;
}

+ (BOOL)toxRequestAvatarInfo:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    int result = tox_request_avatar_info(tox, friendNumber);

    return (result == 0);
}

+ (BOOL)toxRequestAvatarData:(const Tox *)tox friendNumber:(int32_t)friendNumber
{
    NSParameterAssert(tox);

    int result = tox_request_avatar_data(tox, friendNumber);

    return (result == 0);
}

#pragma mark -  Helper methods

+ (BOOL)checkLengthOfString:(NSString *)string withCheckType:(OCTToxWrapperCheckLengthType)type
{
    return [self checkString:string withMaxBytesLength:[self maxLengthForCheckLengthType:type]];
}

+ (NSString *)cropString:(NSString *)string toFitType:(OCTToxWrapperCheckLengthType)type
{
    return [self cropString:string withMaxBytesLength:[self maxLengthForCheckLengthType:type]];
}

+ (NSUInteger)maximumDataLengthForType:(OCTToxWrapperDataLengthType)type
{
    switch(type) {
        case OCTToxWrapperDataLengthTypeAvatar:
            return TOX_AVATAR_MAX_DATA_LENGTH;
    }
}

#pragma mark -  Private

+ (uint32_t)toxSendMessageOrAction:(Tox *)tox
                      friendNumber:(int32_t)friendNumber
                   messageOrAction:(NSString *)messageOrAction
                         isMessage:(BOOL)isMessage
{
    if (isMessage) {
        DDLogVerbose(@"OCTToxWrapper: send message to friendNumber %d, message %@", friendNumber, messageOrAction);
    }
    else {
        DDLogVerbose(@"OCTToxWrapper: send action to friendNumber %d, action %@", friendNumber, messageOrAction);
    }

    if (! [self checkLengthOfString:messageOrAction withCheckType:OCTToxWrapperCheckLengthTypeSendMessage]) {
        messageOrAction = [self cropString:messageOrAction toFitType:OCTToxWrapperCheckLengthTypeSendMessage];
    }

    const char *cMessage = [messageOrAction cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [messageOrAction lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    uint32_t result = 0;

    if (isMessage) {
        result = tox_send_message(tox, friendNumber, (uint8_t *)cMessage, length);
    }
    else {
        result = tox_send_action(tox, friendNumber, (uint8_t *)cMessage, length);
    }

    return result;
}

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

+ (NSUInteger)maxLengthForCheckLengthType:(OCTToxWrapperCheckLengthType)type
{
    switch(type) {
        case OCTToxWrapperCheckLengthTypeFriendRequest:
            return TOX_MAX_FRIENDREQUEST_LENGTH;
        case OCTToxWrapperCheckLengthTypeSendMessage:
            return TOX_MAX_MESSAGE_LENGTH;
        case OCTToxWrapperCheckLengthTypeName:
            return TOX_MAX_NAME_LENGTH;
        case OCTToxWrapperCheckLengthTypeStatusMessage:
            return TOX_MAX_STATUSMESSAGE_LENGTH;
    }
}

+ (BOOL)checkString:(NSString *)string withMaxBytesLength:(NSUInteger)maxLength
{
    NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    return length <= maxLength;
}

+ (NSString *)cropString:(NSString *)string withMaxBytesLength:(NSUInteger)maxLength
{
    NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    if (length <= maxLength) {
        return string;
    }

    return [self substringFromString:string toByteLength:maxLength usingEncoding:NSUTF8StringEncoding];
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
