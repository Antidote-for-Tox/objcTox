//
//  OCTToxConstants.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 26.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTToxConstants.h"
#import "tox.h"

NSString *const kOCTToxErrorDomain = @"me.dvor.objcTox.ErrorDomain";

const NSUInteger kOCTToxAddressLength = 2 * TOX_ADDRESS_SIZE;
const NSUInteger kOCTToxPublicKeyLength = 2 * TOX_PUBLIC_KEY_SIZE;
const NSUInteger kOCTToxMaxNameLength = TOX_MAX_NAME_LENGTH;
const NSUInteger kOCTToxMaxStatusMessageLength = TOX_MAX_STATUS_MESSAGE_LENGTH;
const NSUInteger kOCTToxMaxFriendRequestLength = TOX_MAX_FRIEND_REQUEST_LENGTH;
const NSUInteger kOCTToxMaxMessageLength = TOX_MAX_MESSAGE_LENGTH;
const NSUInteger kOCTToxMaxCustomPacketSize = TOX_MAX_CUSTOM_PACKET_SIZE;
const NSUInteger kOCTToxHashLength = TOX_HASH_LENGTH;

