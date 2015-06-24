//
//  OCTTimer.m
//  objcTox
//
//  Created by Chuong Vu on 6/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTTimer.h"
#import "OCTRealmManager.h"
#import "RBQFetchRequest.h"
#import "OCTCall.h"

@interface OCTTimer ()

@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation OCTTimer

- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    [self startTimer];

    return self;
}

- (void)startTimer
{
    @synchronized(self) {
        if (self.timer) {
            return;
        }

        dispatch_queue_t queue = dispatch_queue_create("me.dvor.objcTox.OCTCallQueue", DISPATCH_QUEUE_SERIAL);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        uint64_t interval = NSEC_PER_SEC;
        uint64_t leeway = NSEC_PER_SEC / 1000;
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, interval, leeway);

        __weak OCTTimer *weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            OCTTimer *strongSelf = weakSelf;
            if (! strongSelf) {
                return;
            }
            [self updateDurationForAllCalls];
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

- (void)updateDurationForAllCalls
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status == %d",
                              OCTCallStatusInSession];

    RBQFetchRequest *request = [realmManager fetchRequestForClass:[OCTCall class] withPredicate:predicate];
    RLMResults *results = [request fetchObjects];

    for (OCTCall *call in results) {
        [realmManager updateObject:call withBlock:^(id theObject) {
            call.callDuration += 1;
        }];
    }
}
@end
