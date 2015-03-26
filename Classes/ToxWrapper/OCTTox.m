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


tox_self_connection_status_cb   connectionStatusCallback;
tox_friend_name_cb              friendNameCallback;
tox_friend_status_message_cb    friendStatusMessageCallback;
tox_friend_status_cb            friendStatusCallback;
tox_friend_connection_status_cb friendConnectionStatusCallback;
tox_friend_typing_cb            friendTypingCallback;
tox_friend_read_receipt_cb      friendReadReceiptCallback;
tox_friend_request_cb           friendRequestCallback;
tox_friend_message_cb           friendMessageCallback;


@interface OCTTox()

@property (assign, nonatomic) Tox *tox;

@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation OCTTox

#pragma mark -  Class methods

+ (NSString *)version
{
    return [NSString stringWithFormat:@"%lu.%lu.%lu", (unsigned long)[self versionMajor], [self versionMinor], [self versionPath]];
}

+ (NSUInteger)versionMajor
{
    return tox_version_major();
}

+ (NSUInteger)versionMinor
{
    return tox_version_minor();
}

+ (NSUInteger)versionPath
{
    return tox_version_patch();
}

#pragma mark -  Lifecycle

- (instancetype)initWithOptions:(OCTToxOptions *)options savedData:(NSData *)data error:(NSError **)error
{
    self = [super init];

    if (! self) {
        return nil;
    }

    struct Tox_Options cOptions;

    if (options) {
        DDLogVerbose(@"%@: init with options:\nIPv6Enabled %d\nUDPEnabled %d\nstartPort %u\nendPort %u\nproxyType %lu\nproxyHost %@\nproxyPort %d",
                self, options.IPv6Enabled, options.UDPEnabled, options.startPort, options.endPort, options.proxyType, options.proxyHost, options.proxyPort);

        cOptions = [self cToxOptionsFromOptions:options];
    }
    else {
        DDLogVerbose(@"%@: init without options", self);
        tox_options_default(&cOptions);
    }

    if (data) {
        DDLogVerbose(@"%@: loading from data of length %lu", self, data.length);
    }

    TOX_ERR_NEW cError;

    _tox = tox_new(&cOptions, (uint8_t *)data.bytes, (uint32_t)data.length, &cError);

    if (cError != TOX_ERR_NEW_OK && error) {
        *error = [self createInitErrorFromCError:cError];
    }

    tox_callback_self_connection_status   (_tox, connectionStatusCallback,       (__bridge void *)self);
    tox_callback_friend_name              (_tox, friendNameCallback,             (__bridge void *)self);
    tox_callback_friend_status_message    (_tox, friendStatusMessageCallback,    (__bridge void *)self);
    tox_callback_friend_status            (_tox, friendStatusCallback,           (__bridge void *)self);
    tox_callback_friend_connection_status (_tox, friendConnectionStatusCallback, (__bridge void *)self);
    tox_callback_friend_typing            (_tox, friendTypingCallback,           (__bridge void *)self);
    tox_callback_friend_read_receipt      (_tox, friendReadReceiptCallback,      (__bridge void *)self);
    tox_callback_friend_request           (_tox, friendRequestCallback,          (__bridge void *)self);
    tox_callback_friend_message           (_tox, friendMessageCallback,          (__bridge void *)self);

    
    return self;
}

- (void)dealloc
{
    [self stop];
    tox_kill(self.tox);

    DDLogVerbose(@"%@: dealloc called, tox killed", self);
}

- (NSData *)save
{
    DDLogVerbose(@"%@: saving...", self);

    size_t size = tox_get_savedata_size(self.tox);
    uint8_t *cData = malloc(size);

    tox_get_savedata(self.tox, cData);

    NSData *data = [NSData dataWithBytes:cData length:size];
    free(cData);

    DDLogInfo(@"%@: saved to data with length %lu", self, data.length);

    return data;
}

- (void)start
{
    DDLogVerbose(@"%@: start method called", self);

    @synchronized(self) {
        if (self.timer) {
            DDLogWarn(@"%@: already started", self);
            return;
        }

        dispatch_queue_t queue = dispatch_queue_create("me.dvor.objcTox.OCTToxQueue", NULL);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

        uint64_t interval = tox_iteration_interval(self.tox) * (NSEC_PER_SEC / 1000);
        dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), interval, interval / 5);

        __weak OCTTox *weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            OCTTox *strongSelf = weakSelf;
            if (! strongSelf) {
                return;
            }

            tox_iterate(strongSelf.tox);
        });

        dispatch_resume(self.timer);
    }

    DDLogInfo(@"%@: started", self);
}

- (void)stop
{
    DDLogVerbose(@"%@: stop method called", self);

    @synchronized(self) {
        if (! self.timer) {
            DDLogWarn(@"%@: tox isn't running, nothing to stop", self);
            return;
        }

        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }

    DDLogInfo(@"%@: stopped", self);
}

#pragma mark -  Properties

- (OCTToxConnectionStatus)connectionStatus
{
    return [self userConnectionStatusFromCUserStatus:tox_self_get_connection_status(self.tox)];
}

- (NSString *)userAddress
{
    const NSUInteger length = kOCTToxAddressLength;
    uint8_t *cAddress = malloc(length);

    tox_self_get_address(self.tox, cAddress);

    if (! cAddress) {
        return nil;
    }

    NSString *address = [self binToHexString:cAddress length:length];

    free(cAddress);

    DDLogVerbose(@"%@: get address: %@", self, address);

    return address;
}

- (void)setUserStatus:(OCTToxUserStatus)status
{
    uint8_t cStatus = TOX_USER_STATUS_NONE;

    switch(status) {
        case OCTToxUserStatusNone:
            cStatus = TOX_USER_STATUS_NONE;
            break;
        case OCTToxUserStatusAway:
            cStatus = TOX_USER_STATUS_AWAY;
            break;
        case OCTToxUserStatusBusy:
            cStatus = TOX_USER_STATUS_BUSY;
            break;
    }

    tox_self_set_status(self.tox, cStatus);

    DDLogInfo(@"%@: set user status to %lu", self, status);
}

- (OCTToxUserStatus)userStatus
{
    return [self userStatusFromCUserStatus:tox_self_get_status(self.tox)];
}

#pragma mark -  Methods

- (BOOL)bootstrapFromHost:(NSString *)host port:(uint16_t)port publicKey:(NSString *)publicKey error:(NSError **)error
{
    NSParameterAssert(host);
    NSParameterAssert(publicKey);

    DDLogInfo(@"%@: bootstrap with host %@ port %d publicKey %@", self, host, port, publicKey);

    const char *cAddress = host.UTF8String;
    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    TOX_ERR_BOOTSTRAP cError;

    bool result = tox_bootstrap(self.tox, cAddress, port, cPublicKey, &cError);

    if (cError != TOX_ERR_BOOTSTRAP_OK && error) {
        *error = [self createBootstrapErrorFromCError:cError];
    }

    free(cPublicKey);

    return (BOOL)result;
}

- (BOOL)addTCPRelayWithHost:(NSString *)host port:(uint16_t)port publicKey:(NSString *)publicKey error:(NSError **)error
{
    NSParameterAssert(host);
    NSParameterAssert(publicKey);

    DDLogInfo(@"%@: add TCP relay with host %@ port %d publicKey %@", self, host, port, publicKey);

    const char *cAddress = host.UTF8String;
    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    TOX_ERR_BOOTSTRAP cError;

    bool result = tox_add_tcp_relay(self.tox, cAddress, port, cPublicKey, &cError);

    if (cError != TOX_ERR_BOOTSTRAP_OK && error) {
        *error = [self createBootstrapErrorFromCError:cError];
    }

    free(cPublicKey);

    return (BOOL)result;
}

- (uint32_t)addFriendWithAddress:(NSString *)address message:(NSString *)message error:(NSError **)error
{
    NSParameterAssert(address);
    NSParameterAssert(message);
    NSAssert(address.length == kOCTToxAddressLength, @"Address must be kOCTToxAddressLength length");

    DDLogVerbose(@"%@: add friend with address %@, message %@", self, address, message);

    uint8_t *cAddress = [self hexStringToBin:address];
    const char *cMessage = [message cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    TOX_ERR_FRIEND_ADD cError;

    uint32_t result = tox_friend_add(self.tox, cAddress, (const uint8_t *)cMessage, length, &cError);

    free(cAddress);

    if (cError != TOX_ERR_FRIEND_ADD_OK && error) {
        *error = [self createFriendAddErrorFromCError:cError];
    }

    return result;
}

- (uint32_t)addFriendWithNoRequestWithPublicKey:(NSString *)publicKey error:(NSError **)error
{
    NSParameterAssert(publicKey);
    NSAssert(publicKey.length == kOCTToxPublicKeyLength, @"Public key must be kOCTToxPublicKeyLength length");

    DDLogVerbose(@"%@: add friend with no request and public key %@", self, publicKey);

    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    TOX_ERR_FRIEND_ADD cError;

    uint32_t result = tox_friend_add_norequest(self.tox, cPublicKey, &cError);

    free(cPublicKey);

    if (cError != TOX_ERR_FRIEND_ADD_OK && error) {
        *error = [self createFriendAddErrorFromCError:cError];
    }

    return result;
}

- (BOOL)deleteFriendWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    TOX_ERR_FRIEND_DELETE cError;

    bool result = tox_friend_delete(self.tox, friendNumber, &cError);

    if (cError != TOX_ERR_FRIEND_DELETE_OK && error) {
        *error = [self createFriendDeleteErrorFromCError:cError];
    }

    DDLogVerbose(@"%@: deleting friend with friendNumber %d, result %d", self, friendNumber, (result == 0));

    return (BOOL)result;
}

- (uint32_t)friendNumberWithPublicKey:(NSString *)publicKey error:(NSError **)error
{
    NSParameterAssert(publicKey);
    NSAssert(publicKey.length == kOCTToxPublicKeyLength, @"Public key must be kOCTToxPublicKeyLength length");

    DDLogVerbose(@"%@: get friend number with public key %@", self, publicKey);

    uint8_t *cPublicKey = [self hexStringToBin:publicKey];

    TOX_ERR_FRIEND_BY_PUBLIC_KEY cError;

    uint32_t result = tox_friend_by_public_key(self.tox, cPublicKey, &cError);

    free(cPublicKey);

    if (cError != TOX_ERR_FRIEND_BY_PUBLIC_KEY_OK && error) {
        *error = [self createFriendByPublicKeyErrorFromCError:cError];
    }

    return result;
}

- (NSString *)publicKeyFromFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    DDLogVerbose(@"%@: get public key from friend number %d", self, friendNumber);

    uint8_t *cPublicKey = malloc(kOCTToxPublicKeyLength);

    TOX_ERR_FRIEND_GET_PUBLIC_KEY cError;

    bool result = tox_friend_get_public_key(self.tox, friendNumber, cPublicKey, &cError);

    NSString *publicKey = nil;

    if (result) {
        publicKey = [self binToHexString:cPublicKey length:kOCTToxPublicKeyLength];
        free(cPublicKey);
    }

    if (cError != TOX_ERR_FRIEND_GET_PUBLIC_KEY_OK && error) {
        *error = [self createFriendGetPublicKeyErrorFromCError:cError];
    }

    DDLogInfo(@"%@: public key %@ from friend number %d", self, publicKey, friendNumber);

    return publicKey;
}

- (BOOL)friendExistsWithFriendNumber:(uint32_t)friendNumber
{
    bool result = tox_friend_exists(self.tox, friendNumber);

    return (BOOL)result;
}

- (OCTToxUserStatus)friendStatusWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    TOX_ERR_FRIEND_QUERY cError;

    TOX_USER_STATUS cStatus = tox_friend_get_status(self.tox, friendNumber, &cError);

    if (cError != TOX_ERR_FRIEND_QUERY_OK && error) {
        *error = [self createFriendQueryErrorFromCError:cError];
    }

    return [self userStatusFromCUserStatus:cStatus];
}

- (OCTToxConnectionStatus)friendConnectionStatusWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    TOX_ERR_FRIEND_QUERY cError;

    TOX_CONNECTION cStatus = tox_friend_get_connection_status(self.tox, friendNumber, &cError);

    if (cError != TOX_ERR_FRIEND_QUERY_OK && error) {
        *error = [self createFriendQueryErrorFromCError:cError];
    }

    return [self userConnectionStatusFromCUserStatus:cStatus];
}

- (uint32_t)sendMessageWithFriendNumber:(uint32_t)friendNumber
                                   type:(OCTToxMessageType)type
                                message:(NSString *)message
                                  error:(NSError **)error
{
    NSParameterAssert(message);

    const char *cMessage = [message cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    TOX_MESSAGE_TYPE cType;
    switch(type) {
        case OCTToxMessageTypeNormal:
            cType = TOX_MESSAGE_TYPE_NORMAL;
            break;
        case OCTToxMessageTypeAction:
            cType = TOX_MESSAGE_TYPE_ACTION;
            break;
    }

    TOX_ERR_FRIEND_SEND_MESSAGE cError;

    uint32_t result = tox_friend_send_message(self.tox, friendNumber, cType, (const uint8_t *)cMessage, length, &cError);

    if (cError != TOX_ERR_FRIEND_SEND_MESSAGE_OK && error) {
        *error = [self createFriendSendMessageErrorFromCError:cError];
    }

    return result;
}

- (BOOL)setNickname:(NSString *)name error:(NSError **)error
{
    NSParameterAssert(name);

    const char *cName = [name cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    TOX_ERR_SET_INFO cError;

    bool result = tox_self_set_name(self.tox, (const uint8_t *)cName, length, &cError);

    if (cError != TOX_ERR_SET_INFO_OK && error) {
        *error = [self createSetInfoErrorFromCError:cError];
    }

    DDLogInfo(@"%@: set userName to %@, result %d", self, name, result);

    return (BOOL)result;
}

- (NSString *)userName
{
    size_t length = tox_self_get_name_size(self.tox);

    if (! length) {
        return nil;
    }

    uint8_t *cName = malloc(length);
    tox_self_get_name(self.tox, cName);

    NSString *name = [[NSString alloc] initWithBytes:cName length:length encoding:NSUTF8StringEncoding];

    free(cName);

    return name;
}

- (NSString *)friendNameWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    TOX_ERR_FRIEND_QUERY cError;
    size_t size = tox_friend_get_name_size(self.tox, friendNumber, &cError);

    if (cError != TOX_ERR_FRIEND_QUERY_OK) {
        if (error) {
            *error = [self createFriendQueryErrorFromCError:cError];
        }

        return nil;
    }

    uint8_t *cName = malloc(size);
    bool result = tox_friend_get_name(self.tox, friendNumber, cName, &cError);

    NSString *name = nil;

    if (result) {
        name = [[NSString alloc] initWithBytes:cName length:size encoding:NSUTF8StringEncoding];

        free(cName);
    }

    if (cError != TOX_ERR_FRIEND_QUERY_OK && error) {
        *error = [self createFriendQueryErrorFromCError:cError];
    }

    return name;
}

- (BOOL)setUserStatusMessage:(NSString *)statusMessage error:(NSError **)error
{
    NSParameterAssert(statusMessage);

    const char *cStatusMessage = [statusMessage cStringUsingEncoding:NSUTF8StringEncoding];
    uint16_t length = [statusMessage lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    TOX_ERR_SET_INFO cError;

    bool result = tox_self_set_status_message(self.tox, (const uint8_t *)cStatusMessage, length, &cError);

    if (cError != TOX_ERR_SET_INFO_OK && error) {
        *error = [self createSetInfoErrorFromCError:cError];
    }

    DDLogInfo(@"%@: set user status message to %@, result %d", self, statusMessage, result);

    return (BOOL)result;
}

- (NSString *)userStatusMessage
{
    size_t length = tox_self_get_status_message_size(self.tox);

    if (! length) {
        return nil;
    }

    uint8_t *cBuffer = malloc(length);

    tox_self_get_status_message(self.tox, cBuffer);

    NSString *message = [[NSString alloc] initWithBytes:cBuffer length:length encoding:NSUTF8StringEncoding];
    free(cBuffer);

    return message;
}

- (NSString *)friendStatusMessageWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    TOX_ERR_FRIEND_QUERY cError;

    size_t size = tox_friend_get_status_message_size(self.tox, friendNumber, &cError);

    if (cError != TOX_ERR_FRIEND_QUERY_OK) {
        if (error) {
            *error = [self createFriendQueryErrorFromCError:cError];
        }

        return nil;
    }

    uint8_t *cBuffer = malloc(size);

    bool result = tox_friend_get_status_message(self.tox, friendNumber, cBuffer, &cError);

    NSString *message = nil;

    if (result) {
        message = [[NSString alloc] initWithBytes:cBuffer length:size encoding:NSUTF8StringEncoding];
        free(cBuffer);
    }

    if (cError != TOX_ERR_FRIEND_QUERY_OK && error) {
        *error = [self createFriendQueryErrorFromCError:cError];
    }

    return message;
}

// - (NSDate *)lastOnlineWithFriendNumber:(uint32_t)friendNumber
// {
//     uint64_t timestamp = tox_get_last_online(self.tox, friendNumber);

//     if (! timestamp) {
//         return nil;
//     }

//     return [NSDate dateWithTimeIntervalSince1970:timestamp];
// }

- (BOOL)setUserIsTyping:(BOOL)isTyping forFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    TOX_ERR_SET_TYPING cError;

    bool result = tox_self_set_typing(self.tox, friendNumber, (bool)isTyping, &cError);

    if (cError != TOX_ERR_SET_TYPING_OK && error) {
        *error = [self createIsTypingErrorFromCError:cError];
    }

    DDLogInfo(@"%@: set user isTyping to %d for friend number %d, result %d", self, isTyping, friendNumber, result);

    return (BOOL)result;
}

- (BOOL)isFriendTypingWithFriendNumber:(uint32_t)friendNumber error:(NSError **)error
{
    TOX_ERR_FRIEND_QUERY cError;

    bool isTyping = tox_friend_get_typing(self.tox, friendNumber, &cError);

    if (cError != TOX_ERR_FRIEND_QUERY_OK && error) {
        *error = [self createFriendQueryErrorFromCError:cError];
    }

    return (BOOL)isTyping;
}

- (NSUInteger)friendsCount
{
    return tox_self_get_friend_list_size(self.tox);
}

// - (NSUInteger)friendsOnlineCount
// {
//     return tox_get_num_online_friends(self.tox);
// }

- (NSArray *)friendsArray
{
    size_t count = tox_self_get_friend_list_size(self.tox);

    if (! count) {
        return @[];
    }

    size_t listSize = count * sizeof(uint32_t);
    uint32_t *cList = malloc(listSize);

    tox_self_get_friend_list(self.tox, cList);

    NSMutableArray *list = [NSMutableArray new];

    for (NSUInteger index = 0; index < count; index++) {
        int32_t friendId = cList[index];
        [list addObject:@(friendId)];
    }

    free(cList);

    DDLogVerbose(@"%@: friend array %@", self, list);

    return [list copy];
}

// - (BOOL)setAvatar:(NSData *)data
// {
//     int result = -1;

//     if (data) {
//         if (data.length > [self maximumDataLengthForType:OCTToxDataLengthTypeAvatar]) {
//             return NO;
//         }

//         const uint8_t *bytes = [data bytes];

//         result = tox_set_avatar(self.tox, TOX_AVATAR_FORMAT_PNG, bytes, (uint32_t)data.length);

//         DDLogInfo(@"%@: set avatar with result %d", self, (result == 0));
//     }
//     else {
//         result = tox_unset_avatar(self.tox);

//         DDLogInfo(@"%@: unset avatar with result %d", self, (result == 0));
//     }

//     return (result == 0);
// }

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

    DDLogInfo(@"%@: hash data result %@", self, hash);

    return hash;
}

// - (BOOL)requestAvatarHashWithFriendNumber:(uint32_t)friendNumber
// {
//     int result = tox_request_avatar_info(self.tox, friendNumber);

//     DDLogInfo(@"%@: request avatar hash from friend number %d, result %d", self, friendNumber, result);

//     return (result == 0);
// }

// - (BOOL)requestAvatarDataWithFriendNumber:(uint32_t)friendNumber
// {
//     int result = tox_request_avatar_data(self.tox, friendNumber);

//     DDLogInfo(@"%@: request avatar data from friend number %d, result %d", self, friendNumber, result);

//     return (result == 0);
// }

// - (BOOL)sendAvatarInfoToFriendNumber:(uint32_t)friendNumber
// {
//     int result = tox_send_avatar_info(self.tox, friendNumber);

//     DDLogInfo(@"%@: send avatar info sent to friend number %d, result %d", self, friendNumber, result);
//     return (result == 0);
// }

// - (int)fileSendRequestWithFriendNumber:(uint32_t)friendNumber fileName:(NSString *)fileName fileSize:(uint64_t)fileSize
// {
//     const char *cFileName = [fileName cStringUsingEncoding:NSUTF8StringEncoding];
//     uint16_t cFileNameLength = [fileName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
//     int result = tox_new_file_sender(self.tox, friendNumber, fileSize, (const uint8_t *)cFileName, cFileNameLength);
    
//     DDLogInfo(@"%@: send a file send request to friend number %d, result %d", self, friendNumber, result);
    
//     return result;
// }

// - (BOOL)fileSendControlWithFriendNumber:(uint32_t)friendNumber
//                           sendOrReceive:(OCTToxFileControlType)sendOrReceive
//                              fileNumber:(uint8_t)fileNumber
//                             controlType:(OCTToxFileControl)controlType
//                                    data:(NSData *)data
// {
//     uint8_t cSendOrReceive = [self typeOfFileControl:sendOrReceive];
//     const uint8_t *cData = (const uint8_t *)[data bytes];
//     uint16_t cLength = (uint16_t)[data length];
//     uint8_t cControlType = TOX_FILECONTROL_ACCEPT;
    
//     switch (controlType) {
//         case OCTToxFileControlAccept:
//             cControlType = TOX_FILECONTROL_ACCEPT;
//             break;
//         case OCTToxFileControlFinished:
//             cControlType = TOX_FILECONTROL_FINISHED;
//             break;
//         case OCTToxFileControlKill:
//             cControlType = TOX_FILECONTROL_KILL;
//             break;
//         case OCTToxFileControlPause:
//             cControlType = TOX_FILECONTROL_PAUSE;
//             break;
//         case OCTToxFileControlResumeBroken:
//             cControlType = TOX_FILECONTROL_RESUME_BROKEN;
//             break;
//         default:
//             break;
//     }
    
//     int result = tox_file_send_control(self.tox, friendNumber, cSendOrReceive, fileNumber, cControlType, cData, cLength);
    
//     return (result == 0);
// }

// - (BOOL)fileSendDataWithFriendNumber:(uint32_t)friendNumber fileNumber:(uint8_t)fileNumber data:(NSData *)data
// {
//     const uint8_t *cData = (const uint8_t *)[data bytes];
//     uint16_t cLength = (uint16_t)[data length];
    
//     int result = tox_file_send_data(self.tox, friendNumber, fileNumber, cData, cLength);
    
//     return (result == 0);
// }

// - (int)fileDataSizeWithFriendNumber:(uint32_t)friendNumber
// {
//     int size = tox_file_data_size(self.tox, friendNumber);
    
//     return size;
// }

// - (uint64_t)fileDataRemainingWithFriendNumber:(uint32_t)friendNumber
//                                    fileNumber:(uint8_t)fileNumber
//                                 sendOrReceive:(OCTToxFileControlType)sendOrReceive
// {
//     uint8_t cSendOrReceive = [self typeOfFileControl:sendOrReceive];
    
//     uint64_t dataRemaining = tox_file_data_remaining(self.tox, friendNumber, fileNumber, cSendOrReceive);
    
//     return dataRemaining;
// }

#pragma mark -  Helper methods

// - (BOOL)checkLengthOfString:(NSString *)string withCheckType:(OCTToxCheckLengthType)type
// {
//     return [self checkString:string withMaxBytesLength:[self maxLengthForCheckLengthType:type]];
// }

#pragma mark -  Private methods

- (OCTToxUserStatus)userStatusFromCUserStatus:(TOX_USER_STATUS)cStatus
{
    switch(cStatus) {
        case TOX_USER_STATUS_NONE:
            return OCTToxUserStatusNone;
        case TOX_USER_STATUS_AWAY:
            return OCTToxUserStatusAway;
        case TOX_USER_STATUS_BUSY:
            return OCTToxUserStatusBusy;
    }
}

- (OCTToxConnectionStatus)userConnectionStatusFromCUserStatus:(TOX_CONNECTION)cStatus
{
    switch(cStatus) {
        case TOX_CONNECTION_NONE:
            return OCTToxConnectionStatusNone;
        case TOX_CONNECTION_TCP:
            return OCTToxConnectionStatusTCP;
        case TOX_CONNECTION_UDP:
            return OCTToxConnectionStatusUDP;
    }
}

- (OCTToxMessageType)messageTypeFromCMessageType:(TOX_MESSAGE_TYPE)cType
{
    switch(cType) {
        case TOX_MESSAGE_TYPE_NORMAL:
            return OCTToxMessageTypeNormal;
        case TOX_MESSAGE_TYPE_ACTION:
            return OCTToxMessageTypeAction;
    }
}

- (NSError *)createInitErrorFromCError:(TOX_ERR_NEW)cError
{
    if (cError == TOX_ERR_NEW_OK) {
        return nil;
    }

    OCTToxErrorInitCode code = OCTToxErrorInitCodeUnknown;
    NSString *description = @"Cannot initialize Tox";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_NEW_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_NEW_NULL:
        case TOX_ERR_NEW_LOAD_DECRYPTION_FAILED:
            code = OCTToxErrorInitCodeUnknown;
            failureReason = @"Unknown error occured";
            break;
        case TOX_ERR_NEW_MALLOC:
            code = OCTToxErrorInitCodeMemoryError;
            failureReason = @"Not enough memory";
            break;
        case TOX_ERR_NEW_PORT_ALLOC:
            code = OCTToxErrorInitCodePortAlloc;
            failureReason = @"Cannot bint to a port";
            break;
        case TOX_ERR_NEW_PROXY_BAD_TYPE:
            code = OCTToxErrorInitCodeProxyBadType;
            failureReason = @"Proxy type is invalid";
            break;
        case TOX_ERR_NEW_PROXY_BAD_HOST:
            code = OCTToxErrorInitCodeProxyBadHost;
            failureReason = @"Proxy host is invalid";
            break;
        case TOX_ERR_NEW_PROXY_BAD_PORT:
            code = OCTToxErrorInitCodeProxyBadPort;
            failureReason = @"Proxy port is invalid";
            break;
        case TOX_ERR_NEW_PROXY_NOT_FOUND:
            code = OCTToxErrorInitCodeProxyNotFound;
            failureReason = @"Proxy host could not be resolved";
            break;
        case TOX_ERR_NEW_LOAD_ENCRYPTED:
            code = OCTToxErrorInitCodeEncrypted;
            failureReason = @"Tox save is encrypted";
            break;
        case TOX_ERR_NEW_LOAD_BAD_FORMAT:
            code = OCTToxErrorInitCodeLoadBadFormat;
            failureReason = @"Tox save is corrupted";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createBootstrapErrorFromCError:(TOX_ERR_BOOTSTRAP)cError
{
    if (cError == TOX_ERR_BOOTSTRAP_OK) {
        return nil;
    }

    OCTToxErrorBootstrapCode code = OCTToxErrorBootstrapCodeUnknown;
    NSString *description = @"Cannot bootstrap with specified node";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_BOOTSTRAP_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_BOOTSTRAP_NULL:
            code = OCTToxErrorBootstrapCodeUnknown;
            failureReason = @"Unknown error occured";
            break;
        case TOX_ERR_BOOTSTRAP_BAD_HOST:
            code = OCTToxErrorBootstrapCodeBadHost;
            failureReason = @"The host could not be resolved to an IP address, or the IP address passed was invalid";
            break;
        case TOX_ERR_BOOTSTRAP_BAD_PORT:
            code = OCTToxErrorBootstrapCodeBadPort;
            failureReason = @"The port passed was invalid";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createFriendAddErrorFromCError:(TOX_ERR_FRIEND_ADD)cError
{
    if (cError == TOX_ERR_FRIEND_ADD_OK) {
        return nil;
    }

    OCTToxErrorFriendAdd code = OCTToxErrorFriendAddUnknown;
    NSString *description = @"Cannot add friend";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_FRIEND_ADD_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_FRIEND_ADD_NULL:
            code = OCTToxErrorFriendAddUnknown;
            failureReason = @"Unknown error occured";
            break;
        case TOX_ERR_FRIEND_ADD_TOO_LONG:
            code = OCTToxErrorFriendAddTooLong;
            failureReason = @"The message is too long";
            break;
        case TOX_ERR_FRIEND_ADD_NO_MESSAGE:
            code = OCTToxErrorFriendAddNoMessage;
            failureReason = @"No message specified";
            break;
        case TOX_ERR_FRIEND_ADD_OWN_KEY:
            code = OCTToxErrorFriendAddOwnKey;
            failureReason = @"Cannot add own address";
            break;
        case TOX_ERR_FRIEND_ADD_ALREADY_SENT:
            code = OCTToxErrorFriendAddAlreadySent;
            failureReason = @"The request was already sent";
            break;
        case TOX_ERR_FRIEND_ADD_BAD_CHECKSUM:
            code = OCTToxErrorFriendAddBadChecksum;
            failureReason = @"Bad checksum";
            break;
        case TOX_ERR_FRIEND_ADD_SET_NEW_NOSPAM:
            code = OCTToxErrorFriendAddSetNewNospam;
            failureReason = @"The no spam value is outdated";
            break;
        case TOX_ERR_FRIEND_ADD_MALLOC:
            code = OCTToxErrorFriendAddMalloc;
            failureReason = nil;
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createFriendDeleteErrorFromCError:(TOX_ERR_FRIEND_DELETE)cError
{
    if (cError == TOX_ERR_FRIEND_DELETE_OK) {
        return nil;
    }

    OCTToxErrorFriendDelete code = OCTToxErrorFriendDeleteNotFound;
    NSString *description = @"Cannot delete friend";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_FRIEND_DELETE_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_FRIEND_DELETE_FRIEND_NOT_FOUND:
            code = OCTToxErrorFriendDeleteNotFound;
            failureReason = @"Friend not found";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createFriendByPublicKeyErrorFromCError:(TOX_ERR_FRIEND_BY_PUBLIC_KEY)cError
{
    if (cError == TOX_ERR_FRIEND_BY_PUBLIC_KEY_OK) {
        return nil;
    }

    OCTToxErrorFriendByPublicKey code = OCTToxErrorFriendByPublicKeyUnknown;
    NSString *description = @"Cannot get friend by public key";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_FRIEND_BY_PUBLIC_KEY_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_FRIEND_BY_PUBLIC_KEY_NULL:
            code = OCTToxErrorFriendByPublicKeyUnknown;
            failureReason = @"Unknown error occured";
            break;
        case TOX_ERR_FRIEND_BY_PUBLIC_KEY_NOT_FOUND:
            code = OCTToxErrorFriendByPublicKeyNotFound;
            failureReason = @"No friend with the given Public Key exists on the friend list";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createFriendGetPublicKeyErrorFromCError:(TOX_ERR_FRIEND_GET_PUBLIC_KEY)cError
{
    if (cError == TOX_ERR_FRIEND_GET_PUBLIC_KEY_OK) {
        return nil;
    }

    OCTToxErrorFriendGetPublicKey code = OCTToxErrorFriendGetPublicKeyFriendNotFound;
    NSString *description = @"Cannot get public key of a friend";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_FRIEND_GET_PUBLIC_KEY_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_FRIEND_GET_PUBLIC_KEY_FRIEND_NOT_FOUND:
            code = OCTToxErrorFriendGetPublicKeyFriendNotFound;
            failureReason = @"Friend not found";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createSetInfoErrorFromCError:(TOX_ERR_SET_INFO)cError
{
    if (cError == TOX_ERR_SET_INFO_OK) {
        return nil;
    }

    OCTToxErrorSetInfoCode code = OCTToxErrorSetInfoCodeUnknow;
    NSString *description = @"Cannot set user info";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_SET_INFO_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_SET_INFO_NULL:
            code = OCTToxErrorSetInfoCodeUnknow;
            failureReason = @"Unknown error occured";
            break;
        case TOX_ERR_SET_INFO_TOO_LONG:
            code = OCTToxErrorSetInfoCodeTooLong;
            failureReason = @"Specified string is too long";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createFriendQueryErrorFromCError:(TOX_ERR_FRIEND_QUERY)cError
{
    if (cError == TOX_ERR_FRIEND_QUERY_OK) {
        return nil;
    }

    OCTToxErrorFriendQuery code = OCTToxErrorFriendQueryUnknown;
    NSString *description = @"Cannot perform friend query";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_FRIEND_QUERY_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_FRIEND_QUERY_NULL:
            code = OCTToxErrorFriendQueryUnknown;
            failureReason = @"Unknown error occured";
            break;
        case TOX_ERR_FRIEND_QUERY_FRIEND_NOT_FOUND:
            code = OCTToxErrorFriendQueryFriendNotFound;
            failureReason = @"Friend not found";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createIsTypingErrorFromCError:(TOX_ERR_SET_TYPING)cError
{
    if (cError == TOX_ERR_SET_TYPING_OK) {
        return nil;
    }

    OCTToxErrorSetTyping code = OCTToxErrorSetTypingFriendNotFound;
    NSString *description = @"Cannot set typing status for a friend";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_SET_TYPING_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_SET_TYPING_FRIEND_NOT_FOUND:
            code = OCTToxErrorSetTypingFriendNotFound;
            failureReason = @"Friend not found";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createFriendSendMessageErrorFromCError:(TOX_ERR_FRIEND_SEND_MESSAGE)cError
{
    if (cError == TOX_ERR_FRIEND_SEND_MESSAGE_OK) {
        return nil;
    }

    OCTToxErrorFriendSendMessage code = OCTToxErrorFriendSendMessageUnknown;
    NSString *description = @"Cannot send message to a friend";
    NSString *failureReason = nil;

    switch(cError) {
        case TOX_ERR_FRIEND_SEND_MESSAGE_OK:
            NSAssert(NO, @"We shouldn't be here");
            return nil;
        case TOX_ERR_FRIEND_SEND_MESSAGE_NULL:
            code = OCTToxErrorFriendSendMessageUnknown;
            failureReason = @"Unknown error occured";
        case TOX_ERR_FRIEND_SEND_MESSAGE_FRIEND_NOT_FOUND:
            code = OCTToxErrorFriendSendMessageFriendNotFound;
            failureReason = @"Friend not found";
            break;
        case TOX_ERR_FRIEND_SEND_MESSAGE_FRIEND_NOT_CONNECTED:
            code = OCTToxErrorFriendSendMessageFriendNotConnected;
            failureReason = @"Friend not connected";
            break;
        case TOX_ERR_FRIEND_SEND_MESSAGE_SENDQ:
            code = OCTToxErrorFriendSendMessageAlloc;
            failureReason = @"Allocation error";
            break;
        case TOX_ERR_FRIEND_SEND_MESSAGE_TOO_LONG:
            code = OCTToxErrorFriendSendMessageTooLong;
            failureReason = @"Message is too long";
            break;
        case TOX_ERR_FRIEND_SEND_MESSAGE_EMPTY:
            code = OCTToxErrorFriendSendMessageEmpty;
            failureReason = @"Message is empty";
            break;
    };

    return [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createErrorWithCode:(NSUInteger)code
                     description:(NSString *)description
                   failureReason:(NSString *)failureReason
{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    if (description) {
        userInfo[NSLocalizedDescriptionKey] = description;
    }

    if (failureReason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;
    }

    return [NSError errorWithDomain:kOCTToxErrorDomain code:code userInfo:userInfo];
}

- (struct Tox_Options)cToxOptionsFromOptions:(OCTToxOptions *)options
{
    struct Tox_Options cOptions;

    cOptions.ipv6_enabled = (bool)options.IPv6Enabled;
    cOptions.udp_enabled = (bool)options.UDPEnabled;

    switch(options.proxyType) {
        case OCTToxProxyTypeNone:
            cOptions.proxy_type = TOX_PROXY_TYPE_NONE;
            break;
        case OCTToxProxyTypeHTTP:
            cOptions.proxy_type = TOX_PROXY_TYPE_HTTP;
            break;
        case OCTToxProxyTypeSocks5:
            cOptions.proxy_type = TOX_PROXY_TYPE_SOCKS5;
            break;
    }

    cOptions.start_port = options.startPort;
    cOptions.end_port = options.endPort;

    if (options.proxyHost) {
        const char *cHost = options.proxyHost.UTF8String;
        strcpy((char *)cOptions.proxy_host, cHost);
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

// - (NSUInteger)maxLengthForCheckLengthType:(OCTToxCheckLengthType)type
// {
//     switch(type) {
//         case OCTToxCheckLengthTypeFriendRequest:
//             return TOX_MAX_FRIENDREQUEST_LENGTH;
//         case OCTToxCheckLengthTypeSendMessage:
//             return TOX_MAX_MESSAGE_LENGTH;
//         case OCTToxCheckLengthTypeName:
//             return TOX_MAX_NAME_LENGTH;
//         case OCTToxCheckLengthTypeStatusMessage:
//             return TOX_MAX_STATUSMESSAGE_LENGTH;
//     }
// }

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

- (uint8_t)typeOfFileControl:(OCTToxFileControlType)type
{
    switch (type) {
        case OCTToxFileControlTypeSend:
            return 0;
        case OCTToxFileControlTypeReceive:
            return 1;
    }
}

@end

#pragma mark -  Callbacks

void connectionStatusCallback(Tox *cTox, TOX_CONNECTION cStatus, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    OCTToxConnectionStatus status = [tox userConnectionStatusFromCUserStatus:cStatus];

    DDLogCInfo(@"%@: connectionStatusCallback with status %lu", tox, status);

    if ([tox.delegate respondsToSelector:@selector(tox:connectionStatus:)]) {
        [tox.delegate tox:tox connectionStatus:status];
    }
}

void friendNameCallback(Tox *cTox, uint32_t friendNumber, const uint8_t *cName, size_t length, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    NSString *name = [NSString stringWithCString:(const char*)cName encoding:NSUTF8StringEncoding];

    DDLogCInfo(@"%@: nameChangeCallback with name %@, friend number %d", tox, name, friendNumber);

    if ([tox.delegate respondsToSelector:@selector(tox:friendNameUpdate:friendNumber:)]) {
        [tox.delegate tox:tox friendNameUpdate:name friendNumber:friendNumber];
    }
}

void friendStatusMessageCallback(Tox *cTox, uint32_t friendNumber, const uint8_t *cMessage, size_t length, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    NSString *message = [NSString stringWithCString:(const char*)cMessage encoding:NSUTF8StringEncoding];

    DDLogCInfo(@"%@: statusMessageCallback with status message %@, friend number %d", tox, message, friendNumber);

    if ([tox.delegate respondsToSelector:@selector(tox:friendStatusMessageUpdate:friendNumber:)]) {
        [tox.delegate tox:tox friendStatusMessageUpdate:message friendNumber:friendNumber];
    }
}

void friendStatusCallback(Tox *cTox, uint32_t friendNumber, TOX_USER_STATUS cStatus, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    OCTToxUserStatus status = [tox userStatusFromCUserStatus:cStatus];

    DDLogCInfo(@"%@: userStatusCallback with status %lu, friend number %d", tox, status, friendNumber);

    if ([tox.delegate respondsToSelector:@selector(tox:friendStatusUpdate:friendNumber:)]) {
        [tox.delegate tox:tox friendStatusUpdate:status friendNumber:friendNumber];
    }
}

void friendConnectionStatusCallback(Tox *cTox, uint32_t friendNumber, TOX_CONNECTION cStatus, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    OCTToxConnectionStatus status = [tox userConnectionStatusFromCUserStatus:cStatus];

    DDLogCInfo(@"%@: connectionStatusCallback with status %lu, friendNumber %d", tox, status, friendNumber);

    if ([tox.delegate respondsToSelector:@selector(tox:friendConnectionStatusChanged:friendNumber:)]) {
        [tox.delegate tox:tox friendConnectionStatusChanged:status friendNumber:friendNumber];
    }
}

void friendTypingCallback(Tox *cTox, uint32_t friendNumber, bool isTyping, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    DDLogCInfo(@"%@: typingChangeCallback with isTyping %d, friend number %d", tox, isTyping, friendNumber);

    if ([tox.delegate respondsToSelector:@selector(tox:friendIsTypingUpdate:friendNumber:)]) {
        [tox.delegate tox:tox friendIsTypingUpdate:(BOOL)isTyping friendNumber:friendNumber];
    }
}

void friendReadReceiptCallback(Tox *cTox, uint32_t friendNumber, uint32_t messageId, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    DDLogCInfo(@"%@: readReceiptCallback with message id %d, friendNumber %d", tox, messageId, friendNumber);

    if ([tox.delegate respondsToSelector:@selector(tox:messageDelivered:friendNumber:)]) {
        [tox.delegate tox:tox messageDelivered:messageId friendNumber:friendNumber];
    }
}

void friendRequestCallback(Tox *cTox, const uint8_t *cPublicKey, const uint8_t *cMessage, size_t length, void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    NSString *publicKey = [tox binToHexString:(uint8_t *)cPublicKey length:kOCTToxPublicKeyLength];
    NSString *message = [[NSString alloc] initWithBytes:cMessage length:length encoding:NSUTF8StringEncoding];

    DDLogCInfo(@"%@: friendRequestCallback with publicKey %@, message %@", tox, publicKey, message);

    if ([tox.delegate respondsToSelector:@selector(tox:friendRequestWithMessage:publicKey:)]) {
        [tox.delegate tox:tox friendRequestWithMessage:message publicKey:publicKey];
    }
}

void friendMessageCallback(
        Tox *cTox,
        uint32_t friendNumber,
        TOX_MESSAGE_TYPE cType,
        const uint8_t *cMessage,
        size_t length,
        void *userData)
{
    OCTTox *tox = (__bridge OCTTox *)(userData);

    NSString *message = [[NSString alloc] initWithBytes:cMessage length:length encoding:NSUTF8StringEncoding];
    OCTToxMessageType type = [tox messageTypeFromCMessageType:cType];

    DDLogCInfo(@"%@: friendMessageCallback with message %@, friend number %d", tox, message, friendNumber);

    if ([tox.delegate respondsToSelector:@selector(tox:friendMessage:type:friendNumber:)]) {
        [tox.delegate tox:tox friendMessage:message type:type friendNumber:friendNumber];
    }
}


// void avatarInfoCallback(Tox *cTox, uint32_t friendNumber, uint8_t format, uint8_t *cHash, void *userData)
// {
//     OCTTox *tox = (__bridge OCTTox *)(userData);

//     NSData *hash = [NSData dataWithBytes:cHash length:TOX_HASH_LENGTH];

//     DDLogCInfo(@"%@: avatarInfoCallback with hash %@, friendNumber %d", tox, hash, friendNumber);

//     if ([tox.delegate respondsToSelector:@selector(tox:friendAvatarHashUpdate:friendNumber:)]) {
//         [tox.delegate tox:tox friendAvatarHashUpdate:hash friendNumber:friendNumber];
//     }
// }

// void avatarDataCallback(Tox *cTox,
//         uint32_t friendNumber,
//         uint8_t format,
//         uint8_t *cHash,
//         uint8_t *cData,
//         uint32_t datalen,
//         void *userData)
// {
//     OCTTox *tox = (__bridge OCTTox *)(userData);

//     NSData *hash = [NSData dataWithBytes:cHash length:TOX_HASH_LENGTH];
//     NSData *data = [NSData dataWithBytes:cData length:datalen];

//     DDLogCInfo(@"%@: avatarDataCallback with hash %@, friendNumber %d", tox, hash, friendNumber);

//     if ([tox.delegate respondsToSelector:@selector(tox:friendAvatarUpdate:hash:friendNumber:)]) {
//         [tox.delegate tox:tox friendAvatarUpdate:data hash:hash friendNumber:friendNumber];
//     }
// }

// void fileSendRequestCallback(Tox *cTox, uint32_t friendNumber, uint8_t fileNumber, uint64_t fileSize, const uint8_t *cFileName, uint16_t fileNameLength, void *userData)
// {
//     OCTTox *tox = (__bridge OCTTox *)(userData);
    
//     NSString *fileName = [[NSString alloc] initWithBytes:cFileName
//                                                   length:fileNameLength
//                                                 encoding:NSUTF8StringEncoding];

//     DDLogCInfo(@"%@: fileSendRequestCallback with fileName %@, friendNumber %d", tox, fileName, friendNumber);
    
//     if ([tox.delegate respondsToSelector:@selector(tox:fileSendRequestWithFileName:friendNumber:fileSize:)]) {
//         [tox.delegate tox:tox fileSendRequestWithFileName:fileName friendNumber:friendNumber fileSize:fileSize];
//     }
// }


// void fileControlCallback(Tox *cTox, uint32_t friendNumber, uint8_t cSendOrReceive, uint8_t fileNumber, uint8_t cControlType, const uint8_t *cData, uint16_t cLength, void *userData)
// {
//     OCTTox *tox = (__bridge OCTTox *)(userData);
//     NSData *data = [[NSData alloc] initWithBytes:cData length:cLength];
//     OCTToxFileControl controlType = OCTToxFileControlAccept;
//     OCTToxFileControlType sendOrReceive = OCTToxFileControlTypeSend;
    
//     if (cSendOrReceive == 0) {
//         sendOrReceive = OCTToxFileControlTypeSend;
//     }
//     else if (cSendOrReceive == 1) {
//         sendOrReceive= OCTToxFileControlTypeReceive;
//     }
    
//     switch (cControlType) {
//         case TOX_FILECONTROL_ACCEPT:
//             controlType = OCTToxFileControlAccept;
//             break;
//         case TOX_FILECONTROL_FINISHED:
//             controlType = OCTToxFileControlFinished;
//             break;
//         case TOX_FILECONTROL_KILL:
//             controlType = OCTToxFileControlKill;
//             break;
//         case TOX_FILECONTROL_PAUSE:
//             controlType = OCTToxFileControlPause;
//             break;
//         case TOX_FILECONTROL_RESUME_BROKEN:
//             controlType = OCTToxFileControlResumeBroken;
//             break;
//         default:
//             break;
//     }
    
//     DDLogCInfo(@"%@: fileControlCallback with friendnumber %d filenumber %d sendReceive %d controlType %d", tox,
//                   friendNumber, fileNumber, cSendOrReceive, cControlType);
    
//     if ([tox.delegate respondsToSelector:@selector(tox:fileSendControlWithFriendNumber:sendOrReceive:fileNumber:controlType:data:)]) {
//         [tox.delegate tox:tox fileSendControlWithFriendNumber:friendNumber
//                                                 sendOrReceive:sendOrReceive
//                                                    fileNumber:fileNumber
//                                                   controlType:controlType
//                                                          data:data];
//     }
// }

// void fileDataCallback(Tox *cTox, uint32_t friendNumber, uint8_t fileNumber, const uint8_t *cData, uint16_t cLength, void *userData)
// {
//     OCTTox *tox = (__bridge OCTTox *)(userData);
//     NSData *data = [[NSData alloc] initWithBytes:cData length:cLength];
    
//     DDLogCInfo(@"%@: fileDataCallback with friendnumber %d filenumber %d", tox, friendNumber, fileNumber);
    
//     if ([tox.delegate respondsToSelector:@selector(tox:fileSendDataWithFriendNumber:fileNumber:data:)]) {
//         [tox.delegate tox:tox fileSendDataWithFriendNumber:friendNumber
//                                                 fileNumber:fileNumber
//                                                       data:data];
//     }
// }

