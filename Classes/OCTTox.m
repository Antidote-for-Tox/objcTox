//
//  OCTTox.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTTox.h"
#import "tox.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

@interface OCTTox()

@property (assign, nonatomic) Tox *tox;

@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation OCTTox

#pragma mark -  Lifecycle

- (instancetype)initWithOptions:(OCTToxOptions *)options
{
    self = [super init];

    if (! self) {
        return nil;
    }

    if (options) {
        Tox_Options cOptions = [self cToxOptionsFromOptions:options];
        _tox = tox_new(&cOptions);
    }
    else {
        _tox = tox_new(NULL);
    }

    return self;
}

- (void)dealloc
{
    [self stop];
    tox_kill(self.tox);
}

- (OCTToxLoadStatus)loadFromData:(NSData *)data
{
    NSParameterAssert(data);

    int result = tox_load(self.tox, (uint8_t *)data.bytes, (uint32_t)data.length);

    switch(result) {
        case 0:
            return OCTToxLoadStatusSuccess;
        case 1:
            return OCTToxLoadStatusEncryptedSaveData;
        case -1:
        default:
            return OCTToxLoadStatusFailure;
    }
}

- (NSData *)save
{
    uint32_t size = tox_size(self.tox);
    uint8_t *cData = malloc(size);

    tox_save(self.tox, cData);

    NSData *data = [NSData dataWithBytes:cData length:size];
    free(cData);

    return data;
}

- (void)start
{
    @synchronized(self) {
        if (self.timer) {
            return;
        }

        dispatch_queue_t queue = dispatch_queue_create("me.dvor.objcTox.OCTToxQueue", NULL);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

        uint64_t interval = tox_do_interval(self.tox) * (NSEC_PER_SEC / 1000);
        dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), interval, interval / 5);

        __weak OCTTox *weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            OCTTox *strongSelf = weakSelf;
            if (! strongSelf) {
                return;
            }

            tox_do(strongSelf.tox);
        });

        dispatch_resume(self.timer);
    }
}

- (void)stop
{
    @synchronized(self) {
        if (! self.timer) {
            return;
        }

        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

#pragma mark -  Properties

- (BOOL)isConnected
{
    int result = tox_isconnected(self.tox);

    return (result == 1);
}

- (NSString *)userAddress
{
    const NSUInteger length = TOX_FRIEND_ADDRESS_SIZE;
    uint8_t *cAddress = malloc(length);

    tox_get_address(self.tox, cAddress);

    if (! cAddress) {
        return nil;
    }

    NSString *address = [self binToHexString:cAddress length:length];

    free(cAddress);

    DDLogVerbose(@"OCTTox: get address: %@", address);

    return address;
}

#pragma mark -  Methods

- (BOOL)bootstrapFromAddress:(NSString *)address port:(uint16_t)port publicKey:(NSString *)publicKey
{
    NSParameterAssert(address);
    NSParameterAssert(publicKey);

    const char *cAddress = address.UTF8String;
    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int result = tox_bootstrap_from_address(self.tox, cAddress, port, cPublicKey);

    free(cPublicKey);

    return (result == 1);
}

- (BOOL)addTCPRelayWithAddress:(NSString *)address port:(uint16_t)port publicKey:(NSString *)publicKey
{
    NSParameterAssert(address);
    NSParameterAssert(publicKey);

    const char *cAddress = address.UTF8String;
    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int result = tox_bootstrap_from_address(self.tox, cAddress, port, cPublicKey);

    free(cPublicKey);

    return (result == 1);
}

- (int32_t)addFriendWithAddress:(NSString *)address message:(NSString *)message error:(NSError **)error
{
    NSParameterAssert(address);
    NSParameterAssert(message);
    NSAssert(address.length == kOCTToxAddressLength, @"Address must be kOCTToxAddressLength length");

    DDLogVerbose(@"OCTTox: add friend with address %@, message %@", address, message);

    if (! [self checkLengthOfString:message withCheckType:OCTToxCheckLengthTypeFriendRequest]) {
        message = [self cropString:message toFitType:OCTToxCheckLengthTypeFriendRequest];
    }

    uint8_t *cAddress = [self hexStringToBin:address];
    const char *cMessage = [message cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int32_t result = tox_add_friend(self.tox, cAddress, (const uint8_t *)cMessage, length);

    free(cAddress);

    if (result > -1) {
        DDLogInfo(@"OCTTox: add friend: success with friend number %d", result);
        return result;
    }

    OCTToxAddFriendError code = OCTToxAddFriendErrorUnknown;
    NSString *description = @"Cannot add friend";
    NSString *failureReason = nil;

    switch(result) {
        case TOX_FAERR_TOOLONG:
            code = OCTToxAddFriendErrorMessageIsTooLong;
            failureReason = @"The message is too long";
            break;
        case TOX_FAERR_NOMESSAGE:
            code = OCTToxAddFriendErrorNoMessage;
            failureReason = @"No message specified";
            break;
        case TOX_FAERR_OWNKEY:
            code = OCTToxAddFriendErrorOwnAddress;
            failureReason = @"Cannot add own address";
            break;
        case TOX_FAERR_ALREADYSENT:
            code = OCTToxAddFriendErrorAlreadySent;
            failureReason = @"The request was already sent";
            break;
        case TOX_FAERR_UNKNOWN:
            code = OCTToxAddFriendErrorUnknown;
            failureReason = @"Unknown error";
            break;
        case TOX_FAERR_BADCHECKSUM:
            code = OCTToxAddFriendErrorBadChecksum;
            failureReason = @"Bad checksum";
            break;
        case TOX_FAERR_SETNEWNOSPAM:
            code = OCTToxAddFriendErrorSetNewNoSpam;
            failureReason = @"The no spam value is outdated";
            break;
        case TOX_FAERR_NOMEM:
            code = OCTToxAddFriendErrorNoMem;
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

    NSError *theError = [NSError errorWithDomain:kOCTToxErrorDomain code:code userInfo:userInfo];
    if (error) {
        *error = theError;
    }

    DDLogWarn(@"OCTTox: add friend: failure with error %@", theError);

    return -1;
}

- (int32_t)addFriendWithNoRequestWithPublicKey:(NSString *)publicKey
{
    NSParameterAssert(publicKey);
    NSAssert(publicKey.length == kOCTToxPublicKeyLength, @"Public key must be kOCTToxPublicKeyLength length");

    DDLogVerbose(@"OCTTox: add friend with no request and public key %@", publicKey);

    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int32_t result = tox_add_friend_norequest(self.tox, cPublicKey);

    free(cPublicKey);

    if (result < 0) {
        DDLogWarn(@"OCTTox: add friend with no request failed with error");
    }
    else {
        DDLogInfo(@"OCTTox: add friend with no request: success with friend number %d", result);
    }

    return result;
}

- (int32_t)friendNumberWithPublicKey:(NSString *)publicKey
{
    NSParameterAssert(publicKey);
    NSAssert(publicKey.length == kOCTToxPublicKeyLength, @"Public key must be kOCTToxPublicKeyLength length");

    DDLogVerbose(@"OCTTox: get friend number with public key %@", publicKey);

    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    int32_t result = tox_get_friend_number(self.tox, cPublicKey);

    free(cPublicKey);

    if (result < 0) {
        DDLogWarn(@"OCTTox: get friend number with public key failed with error: no such friend");
    }
    else {
        DDLogInfo(@"OCTTox: get friend number with public key success with friend number %d", result);
    }

    return result;
}

- (NSString *)publicKeyFromFriendNumber:(int32_t)friendNumber
{
    DDLogVerbose(@"OCTTox: get public key from friend number %d", friendNumber);

    uint8_t *cPublicKey = malloc(TOX_CLIENT_ID_SIZE);
    int result = tox_get_client_id(self.tox, friendNumber, cPublicKey);

    NSString *publicKey = nil;

    if (result == 0) {
        publicKey = [self binToHexString:cPublicKey length:TOX_CLIENT_ID_SIZE];
        free(cPublicKey);
    }

    return publicKey;
}

- (BOOL)deleteFriendWithFriendNumber:(int32_t)friendNumber
{
    int result = tox_del_friend(self.tox, friendNumber);

    return (result == 0);
}

- (OCTToxConnectionStatus)friendConnectionStatusWithFriendNumber:(int32_t)friendNumber
{
    int result = tox_get_friend_connection_status(self.tox, friendNumber);

    switch(result) {
        case 1:
            return OCTToxConnectionStatusOnline;
        case 0:
            return OCTToxConnectionStatusOffline;
        case -1:
        default:
            return OCTToxConnectionStatusUnknown;
    }
}

- (BOOL)friendExistsWithFriendNumber:(int32_t)friendNumber
{
    int result = tox_friend_exists(self.tox, friendNumber);

    return (result == 1);
}

- (uint32_t)sendMessageWithFriendNumber:(int32_t)friendNumber message:(NSString *)message
{
    NSParameterAssert(message);

    return [self sendMessageOrActionWithFriendNumber:friendNumber messageOrAction:message isMessage:YES];
}

- (uint32_t)friendNumber:(int32_t)friendNumber action:(NSString *)action
{
    NSParameterAssert(action);

    return [self sendMessageOrActionWithFriendNumber:friendNumber messageOrAction:action isMessage:NO];
}

- (BOOL)setUserName:(NSString *)name
{
    NSParameterAssert(name);

    const char *cName = [name cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int result = tox_set_name(self.tox, (const uint8_t *)cName, length);

    return (result == 0);
}

- (NSString *)userName
{
    uint8_t *cName = malloc(TOX_MAX_NAME_LENGTH);
    uint16_t length = tox_get_self_name(self.tox, cName);

    NSString *name = nil;

    if (length) {
        name = [[NSString alloc] initWithBytes:cName length:length encoding:NSUTF8StringEncoding];

        free(cName);
    }

    return name;
}

- (NSString *)friendNameWithFriendNumber:(int32_t)friendNumber
{
    uint8_t *cName = malloc(TOX_MAX_NAME_LENGTH);
    uint16_t length = tox_get_name(self.tox, friendNumber, cName);

    NSString *name = nil;

    if (length) {
        name = [[NSString alloc] initWithBytes:cName length:length encoding:NSUTF8StringEncoding];

        free(cName);
    }

    return name;
}

- (BOOL)setUserStatusMessage:(NSString *)statusMessage
{
    NSParameterAssert(statusMessage);

    if (! [self checkLengthOfString:statusMessage withCheckType:OCTToxCheckLengthTypeStatusMessage]) {
        statusMessage = [self cropString:statusMessage toFitType:OCTToxCheckLengthTypeStatusMessage];
    }

    const char *cStatusMessage = [statusMessage cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [statusMessage lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    int result = tox_set_status_message(self.tox, (const uint8_t *)cStatusMessage, length);

    return (result == 0);
}

- (NSString *)userStatusMessage
{
    int length = tox_get_self_status_message_size(self.tox);

    if (length <= 0) {
        return nil;
    }

    uint8_t *cBuffer = malloc(length);

    tox_get_self_status_message(self.tox, cBuffer, length);

    NSString *message = [[NSString alloc] initWithBytes:cBuffer length:length encoding:NSUTF8StringEncoding];
    free(cBuffer);

    return message;
}

- (BOOL)setUserStatus:(OCTToxUserStatus)status
{
    uint8_t cStatus = TOX_USERSTATUS_NONE;

    switch(status) {
        case OCTToxUserStatusNone:
            cStatus = TOX_USERSTATUS_NONE;
        case OCTToxUserStatusAway:
            cStatus = TOX_USERSTATUS_AWAY;
        case OCTToxUserStatusBusy:
            cStatus = TOX_USERSTATUS_BUSY;
        case OCTToxUserStatusInvalid:
            cStatus = TOX_USERSTATUS_INVALID;
            break;
    }

    int result = tox_set_user_status(self.tox, cStatus);

    return (result == 0);
}

- (NSString *)friendStatusMessageWithFriendNumber:(int32_t)friendNumber
{
    int length = tox_get_status_message_size(self.tox, friendNumber);

    if (length <= 0) {
        return nil;
    }

    uint8_t *cBuffer = malloc(length);

    tox_get_status_message(self.tox, friendNumber, cBuffer, length);

    NSString *message = [[NSString alloc] initWithBytes:cBuffer length:length encoding:NSUTF8StringEncoding];
    free(cBuffer);

    return message;
}

- (NSDate *)lastOnlineWithFriendNumber:(int32_t)friendNumber
{
    uint64_t timestamp = tox_get_last_online(self.tox, friendNumber);

    if (! timestamp) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

- (BOOL)setUserIsTyping:(BOOL)isTyping forFriendNumber:(int32_t)friendNumber
{
    uint8_t cIsTyping = isTyping ? 1 : 0;

    int result = tox_set_user_is_typing(self.tox, friendNumber, cIsTyping);

    return (result == 0);
}

- (BOOL)isFriendTypingWithFriendNumber:(int32_t)friendNumber
{
    uint8_t cIsTyping = tox_get_is_typing(self.tox, friendNumber);

    return (cIsTyping == 1);
}

- (NSUInteger)friendsCount
{
    return tox_count_friendlist(self.tox);
}

- (NSUInteger)friendsOnlineCount
{
    return tox_get_num_online_friends(self.tox);
}

- (NSArray *)friendsArray
{
    uint32_t count = tox_count_friendlist(self.tox);

    if (! count) {
        return @[];
    }

    uint32_t listSize = count * sizeof(int32_t);
    int32_t *cList = malloc(listSize);

    tox_get_friendlist(self.tox, cList, listSize);

    NSMutableArray *list = [NSMutableArray new];

    for (NSUInteger index = 0; index < count; index++) {
        int32_t friendId = cList[index];
        [list addObject:@(friendId)];
    }

    free(cList);

    return [list copy];
}

- (BOOL)setAvatar:(NSData *)data
{
    int result = -1;

    if (data) {
        if (data.length > [self maximumDataLengthForType:OCTToxDataLengthTypeAvatar]) {
            return NO;
        }

        const uint8_t *bytes = [data bytes];

        result = tox_set_avatar(self.tox, TOX_AVATAR_FORMAT_PNG, bytes, (uint32_t)data.length);
    }
    else {
        result = tox_unset_avatar(self.tox);
    }

    return (result == 0);
}

- (NSData *)hashData:(NSData *)data
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

- (BOOL)requestAvatarInfoWithFriendNumber:(int32_t)friendNumber
{
    int result = tox_request_avatar_info(self.tox, friendNumber);

    return (result == 0);
}

- (BOOL)requestAvatarDataWithFriendNumber:(int32_t)friendNumber
{
    int result = tox_request_avatar_data(self.tox, friendNumber);

    return (result == 0);
}

#pragma mark -  Helper methods

- (BOOL)checkLengthOfString:(NSString *)string withCheckType:(OCTToxCheckLengthType)type
{
    return [self checkString:string withMaxBytesLength:[self maxLengthForCheckLengthType:type]];
}

- (NSString *)cropString:(NSString *)string toFitType:(OCTToxCheckLengthType)type
{
    return [self cropString:string withMaxBytesLength:[self maxLengthForCheckLengthType:type]];
}

- (NSUInteger)maximumDataLengthForType:(OCTToxDataLengthType)type
{
    switch(type) {
        case OCTToxDataLengthTypeAvatar:
            return TOX_AVATAR_MAX_DATA_LENGTH;
    }
}

#pragma mark -  Private methods

- (uint32_t)sendMessageOrActionWithFriendNumber:(int32_t)friendNumber
                                messageOrAction:(NSString *)messageOrAction
                                      isMessage:(BOOL)isMessage
{
    if (isMessage) {
        DDLogVerbose(@"OCTTox: send message to friendNumber %d, message %@", friendNumber, messageOrAction);
    }
    else {
        DDLogVerbose(@"OCTTox: send action to friendNumber %d, action %@", friendNumber, messageOrAction);
    }

    if (! [self checkLengthOfString:messageOrAction withCheckType:OCTToxCheckLengthTypeSendMessage]) {
        messageOrAction = [self cropString:messageOrAction toFitType:OCTToxCheckLengthTypeSendMessage];
    }

    const char *cMessage = [messageOrAction cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [messageOrAction lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    uint32_t result = 0;

    if (isMessage) {
        result = tox_send_message(self.tox, friendNumber, (uint8_t *)cMessage, length);
    }
    else {
        result = tox_send_action(self.tox, friendNumber, (uint8_t *)cMessage, length);
    }

    return result;
}

- (Tox_Options)cToxOptionsFromOptions:(OCTToxOptions *)options
{
    Tox_Options cOptions;

    cOptions.ipv6enabled = options.IPv6Enabled ? 1 : 0;
    cOptions.udp_disabled = options.UDPEnabled ? 0 : 1;

    switch(options.proxyType) {
        case OCTToxProxyTypeNone:
            cOptions.proxy_type = TOX_PROXY_NONE;
            break;
        case OCTToxProxyTypeSocks5:
            cOptions.proxy_type = TOX_PROXY_SOCKS5;
            break;
        case OCTToxProxyTypeHTTP:
            cOptions.proxy_type = TOX_PROXY_HTTP;
            break;
    }

    if (options.proxyAddress) {
        const char *cAddress = options.proxyAddress.UTF8String;
        strcpy(cOptions.proxy_address, cAddress);
    }
    cOptions.proxy_port = options.proxyPort;

    return cOptions;
}

- (NSString *)binToHexString:(uint8_t *)bin length:(NSUInteger)length
{
    NSMutableString *string = [NSMutableString stringWithCapacity:length * 2];

    for (NSUInteger idx = 0; idx < length; ++idx) {
        [string appendFormat:@"%02X", bin[idx]];
    }

    return [string copy];
}

// You are responsible for freeing the return value!
- (uint8_t *)hexStringToBin:(NSString *)string
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

- (BOOL)checkString:(NSString *)string withMaxBytesLength:(NSUInteger)maxLength
{
    NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    return length <= maxLength;
}

- (NSString *)cropString:(NSString *)string withMaxBytesLength:(NSUInteger)maxLength
{
    NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    if (length <= maxLength) {
        return string;
    }

    return [self substringFromString:string toByteLength:maxLength usingEncoding:NSUTF8StringEncoding];
}

- (NSUInteger)maxLengthForCheckLengthType:(OCTToxCheckLengthType)type
{
    switch(type) {
        case OCTToxCheckLengthTypeFriendRequest:
            return TOX_MAX_FRIENDREQUEST_LENGTH;
        case OCTToxCheckLengthTypeSendMessage:
            return TOX_MAX_MESSAGE_LENGTH;
        case OCTToxCheckLengthTypeName:
            return TOX_MAX_NAME_LENGTH;
        case OCTToxCheckLengthTypeStatusMessage:
            return TOX_MAX_STATUSMESSAGE_LENGTH;
    }
}

- (NSString *)substringFromString:(NSString *)string
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
