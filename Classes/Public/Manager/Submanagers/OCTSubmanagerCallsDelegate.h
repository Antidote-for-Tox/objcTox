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
 * Delegate for when we receive a call.
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager receiveCall:(OCTCall *)call audioEnabled:(BOOL)audioEnabled videoEnabled:(BOOL)videoEnabled;

/**
 * Audio bitrate has changed
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager audioBitRateChanged:(OCTToxAVAudioBitRate)bitRate stable:(BOOL)stable forCall:(OCTCall *)call;

/**
 * Video bitrate has changed
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager videoBitRateChanged:(OCTToxAVAudioBitRate)bitRate stable:(BOOL)stable forCall:(OCTCall *)call;

/**
 * Call state has changed
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager stateChanged:(OCTToxAVCallState)state forCall:(OCTCall *)call;

@end