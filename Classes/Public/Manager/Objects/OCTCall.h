//
//  OCTCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OCTChat.h"
#import "OCTFriend.h"

typedef NS_ENUM(NSUInteger, OCTCallStatus) {
    OCTCallStatusPaused,
    OCTCallStatusActive,
    OCTCallStatusInActive
};

@interface OCTCall : NSObject

/**
 * OCTChat related session with the call.
 **/
@property (strong, nonatomic, readonly) OCTChat *chatSession;

/**
 * Friend related to the call.
 **/
@property (strong, nonatomic, readonly) OCTFriend *caller;

/**
 * Call status
 **/
@property (nonatomic, assign) OCTCallStatus status;

@end
