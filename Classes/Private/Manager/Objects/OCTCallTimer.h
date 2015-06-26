//
//  OCTCallTimer.h
//  objcTox
//
//  Created by Chuong Vu on 6/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OCTRealmManager;
@class OCTCall;

@interface OCTCallTimer : NSObject

- (instancetype)initWithRealmManager:(OCTRealmManager *)realmManager;

/**
 * Starts the timer for the specified call.
 * Note that there can only be one active call.
 * @param call Call to update.
 */
- (void)startTimerForCall:(OCTCall *)call;

/**
 * Stops the timer for the current call in session.
 */
- (void)stopTimer;

@end
