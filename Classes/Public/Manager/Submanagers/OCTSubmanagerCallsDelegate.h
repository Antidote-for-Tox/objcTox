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

@end
