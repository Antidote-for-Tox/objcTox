//
//  OCTToxConstants.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

typedef NS_ENUM(NSUInteger, OCTToxProxyType) {
    OCTToxProxyTypeNone,
    OCTToxProxyTypeSocks5,
    OCTToxProxyTypeHTTP,
};

typedef NS_ENUM(NSUInteger, OCTToxLoadStatus) {
    OCTToxLoadStatusSuccess,
    OCTToxLoadStatusFailure,
    OCTToxLoadStatusEncryptedSaveData,
};

/**
 * Errors for toxAddFriend method
 */
typedef NS_ENUM(NSUInteger, OCTToxAddFriendError) {
    // Unknown error
    OCTToxAddFriendErrorUnknown = 0,

    // The message is too long
    OCTToxAddFriendErrorMessageIsTooLong,

    // No message specified (message length must be >= 1)
    OCTToxAddFriendErrorNoMessage,

    // The message was send to own address
    OCTToxAddFriendErrorOwnAddress,

    // The friend request was already sent or already is a friend
    OCTToxAddFriendErrorAlreadySent,

    // Bad checksum in address
    OCTToxAddFriendErrorBadChecksum,

    // If the friend was already there but nospam was different
    // (the nospam for that friend was set to the new one).
    OCTToxAddFriendErrorSetNewNoSpam,

    // If increasing the friend list size fails
    OCTToxAddFriendErrorNoMem,
};

typedef NS_ENUM(NSUInteger, OCTToxConnectionStatus) {
    // The status is unknown (for example if there was a failure while getting it)
    OCTToxConnectionStatusUnknown,
    OCTToxConnectionStatusOffline,
    OCTToxConnectionStatusOnline,
};

typedef NS_ENUM(NSUInteger, OCTToxCheckLengthType) {
    OCTToxCheckLengthTypeFriendRequest,
    OCTToxCheckLengthTypeSendMessage,
    OCTToxCheckLengthTypeName,
    OCTToxCheckLengthTypeStatusMessage,
};

typedef NS_ENUM(NSUInteger, OCTToxDataLengthType) {
    OCTToxDataLengthTypeAvatar,
};

typedef NS_ENUM(NSUInteger, OCTToxUserStatus) {
    OCTToxUserStatusNone,
    OCTToxUserStatusAway,
    OCTToxUserStatusBusy,
    OCTToxUserStatusInvalid,
};

typedef NS_ENUM(NSUInteger, OCTToxFileControl) {
    OCTToxFileControlAccept,
    OCTToxFileControlPause,
    OCTToxFileControlKill,
    OCTToxFileControlFinished,
    OCTToxFileControlResumeBroken,
};

typedef NS_ENUM(NSUInteger, OCTToxFileControlType) {
    OCTToxFileControlTypeSend,
    OCTToxFileControlTypeReceive,
};
