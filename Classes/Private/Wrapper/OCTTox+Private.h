//
//  OCTTox+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTTox.h"
#import "tox.h"

/**
 * Tox functions
 */
void (*_tox_self_get_public_key)(const Tox *tox, uint8_t *public_key);

/**
 * Callbacks
 */
tox_self_connection_status_cb connectionStatusCallback;
tox_friend_name_cb friendNameCallback;
tox_friend_status_message_cb friendStatusMessageCallback;
tox_friend_status_cb friendStatusCallback;
tox_friend_connection_status_cb friendConnectionStatusCallback;
tox_friend_typing_cb friendTypingCallback;
tox_friend_read_receipt_cb friendReadReceiptCallback;
tox_friend_request_cb friendRequestCallback;
tox_friend_message_cb friendMessageCallback;
tox_file_recv_control_cb fileReceiveControlCallback;
tox_file_chunk_request_cb fileChunkRequestCallback;
tox_file_recv_cb fileReceiveCallback;
tox_file_recv_chunk_cb fileReceiveChunkCallback;

@interface OCTTox (Private)

@property (assign, nonatomic) Tox *tox;

- (OCTToxUserStatus)userStatusFromCUserStatus:(TOX_USER_STATUS)cStatus;
- (OCTToxConnectionStatus)userConnectionStatusFromCUserStatus:(TOX_CONNECTION)cStatus;
- (OCTToxMessageType)messageTypeFromCMessageType:(TOX_MESSAGE_TYPE)cType;
- (OCTToxFileControl)fileControlFromCFileControl:(TOX_FILE_CONTROL)cControl;
- (void)fillError:(NSError **)error withCErrorInit:(TOX_ERR_NEW)cError;
- (void)fillError:(NSError **)error withCErrorBootstrap:(TOX_ERR_BOOTSTRAP)cError;
- (void)fillError:(NSError **)error withCErrorFriendAdd:(TOX_ERR_FRIEND_ADD)cError;
- (void)fillError:(NSError **)error withCErrorFriendDelete:(TOX_ERR_FRIEND_DELETE)cError;
- (void)fillError:(NSError **)error withCErrorFriendByPublicKey:(TOX_ERR_FRIEND_BY_PUBLIC_KEY)cError;
- (void)fillError:(NSError **)error withCErrorFriendGetPublicKey:(TOX_ERR_FRIEND_GET_PUBLIC_KEY)cError;
- (void)fillError:(NSError **)error withCErrorSetInfo:(TOX_ERR_SET_INFO)cError;
- (void)fillError:(NSError **)error withCErrorFriendGetLastOnline:(TOX_ERR_FRIEND_GET_LAST_ONLINE)cError;
- (void)fillError:(NSError **)error withCErrorFriendQuery:(TOX_ERR_FRIEND_QUERY)cError;
- (void)fillError:(NSError **)error withCErrorSetTyping:(TOX_ERR_SET_TYPING)cError;
- (void)fillError:(NSError **)error withCErrorFriendSendMessage:(TOX_ERR_FRIEND_SEND_MESSAGE)cError;
- (void)fillError:(NSError **)error withCErrorFileControl:(TOX_ERR_FILE_CONTROL)cError;
- (void)fillError:(NSError **)error withCErrorFileSeek:(TOX_ERR_FILE_SEEK)cError;
- (void)fillError:(NSError **)error withCErrorFileGet:(TOX_ERR_FILE_GET)cError;
- (void)fillError:(NSError **)error withCErrorFileSend:(TOX_ERR_FILE_SEND)cError;
- (void)fillError:(NSError **)error withCErrorFileSendChunk:(TOX_ERR_FILE_SEND_CHUNK)cError;
- (NSError *)createErrorWithCode:(NSUInteger)code
                     description:(NSString *)description
                   failureReason:(NSString *)failureReason;
- (struct Tox_Options)cToxOptionsFromOptions:(OCTToxOptions *)options;
- (NSString *)binToHexString:(uint8_t *)bin length:(NSUInteger)length;
- (uint8_t *)hexStringToBin:(NSString *)string;

@end
