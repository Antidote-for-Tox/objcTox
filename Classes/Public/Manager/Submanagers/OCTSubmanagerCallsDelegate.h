//
//  OCTSubmanagerCallsDelegate.h
//  objcTox
//
//  Created by Chuong Vu on 6/23/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

@class OCTCall;
@class OCTSubmanagerCalls;

@protocol OCTSubmanagerCallDelegate <NSObject>

/**
 * This gets called when we receive a call.
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager receiveCall:(OCTCall *)call audioEnabled:(BOOL)audioEnabled videoEnabled:(BOOL)videoEnabled;

/**
 * Call audio status has changed.
 * @param call The call that has been updated.
 * @param enabled YES if the call is now receiving audio. Otherwise NO.
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager call:(OCTCall *)call incomingAudioEnabled:(BOOL)enabled;

/**
 * Call video status has changed.
 * @param call The call that has been updated.
 * @param enabled YES if the call is now receiving video. Otherwise NO.
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager call:(OCTCall *)call incomingVideoEnabled:(BOOL)enabled;

@end
