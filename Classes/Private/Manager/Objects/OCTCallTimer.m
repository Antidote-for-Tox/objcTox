//
//  OCTCallTimer.m
//  objcTox
//
//  Created by Chuong Vu on 6/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCallTimer.h"
#import "OCTRealmManager.h"
#import "RBQFetchRequest.h"
#import "OCTCall.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

@interface OCTCallTimer ()

@property (strong, nonatomic) dispatch_source_t timer;
@property (strong, nonatomic) OCTRealmManager *realmManager;

@end

@implementation OCTCallTimer

- (instancetype)initWithRealmManager:(OCTRealmManager *)realmManager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _realmManager = realmManager;

    return self;
}

- (void)startTimerForCall:(OCTCall *)call
{
    @synchronized(self) {
        if (self.timer) {
            NSAssert(! self.timer, @"There is already a timer in progress!");
        }

        dispatch_queue_t queue = dispatch_queue_create("me.dvor.objcTox.OCTCallQueue", DISPATCH_QUEUE_SERIAL);

        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        uint64_t interval = NSEC_PER_SEC;
        uint64_t leeway = NSEC_PER_SEC / 1000;
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, interval, leeway);

        __weak OCTCallTimer *weakSelf = self;
        __weak OCTCall *weakCall = call;
        dispatch_source_set_event_handler(self.timer, ^{
            OCTCallTimer *strongSelf = weakSelf;
            OCTCall *strongCall = weakCall;
            if ((! strongSelf) ||  (! strongCall)) {
                return;
            }

            [strongSelf.realmManager updateObject:strongCall withBlock:^(OCTCall *callToUpdate) {
                callToUpdate.callDuration += 1.0;
            }];

            DDLogCInfo(@"%@: Call: %@ updated duration by 1 second", self, strongCall);
        });

        dispatch_resume(self.timer);
    }
}

- (void)stopTimer
{
    @synchronized(self) {
        if (! self.timer) {
            return;
        }

        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

@end
