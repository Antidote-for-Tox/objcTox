//
//  OCTToxDelegate.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 03.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"

@class OCTTox;
@protocol OCTToxDelegate <NSObject>

@optional

- (void)tox:(OCTTox *)tox friendRequestWithMessage:(NSString *)message publicKey:(NSString *)publicKey;

- (void)tox:(OCTTox *)tox friendMessage:(NSString *)message friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendAction:(NSString *)action friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendNameUpdate:(NSString *)name friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendStatusMessageUpdate:(NSString *)statusMessage friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendStatusUpdate:(OCTToxUserStatus)status friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendIsTypingUpdate:(BOOL)isTyping friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox messageDelivered:(uint32_t)messageId friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendConnectionStatusChanged:(OCTToxConnectionStatus)status friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendAvatarHashUpdate:(NSData *)hash friendNumber:(int32_t)friendNumber;

- (void)tox:(OCTTox *)tox friendAvatarUpdate:(NSData *)avatar hash:(NSData *)hash friendNumber:(int32_t)friendNumber;

@end
