//
//  OCTCallsContainer.m
//  objcTox
//
//  Created by Chuong Vu on 6/10/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCallsContainer.h"
#import "OCTCallsContainer+Private.h"
#import "OCTBasicContainer.h"

@interface OCTCallsContainer () <OCTBasicContainerDelegate>

@property (strong, nonatomic) OCTBasicContainer *container;

@end

@implementation OCTCallsContainer

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.container = [[OCTBasicContainer alloc] initWithObjects:nil];
    self.container.delegate = self;

    return self;
}
#pragma Public Methods

- (NSUInteger)numberOfCalls
{
    return self.container.count;
}

- (OCTCall *)callAtIndex:(NSUInteger)index
{
    return [self.container objectAtIndex:index];
}

- (OCTCall *)callWithChat:(OCTChat *)chat
{
    NSUInteger index = [self.container indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
        OCTCall *call = obj;
        if (call.chat == chat) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index != NSNotFound) {
        return [self.container objectAtIndex:index];
    }
    return nil;
}

#pragma mark - Private Methods

- (void)addCall:(OCTCall *)call
{
    [self.container addObject:call];
}

- (void)removeCall:(OCTCall *)call
{
    [self.container removeObject:call];
}

- (void)updateCall:(OCTCall *)call
       updateBlock:(void (^)(OCTCall *call))updateBlock
{
    [self.container updateObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
        OCTCall *otherCall = obj;
        if (call.chat.uniqueIdentifier == otherCall.chat.uniqueIdentifier) {
            *stop = YES;
            return YES;
        }
        return NO;
    } updateBlock:updateBlock];
}

#pragma mark - Delegate Methods

- (void)basicContainer:(OCTBasicContainer *)container objectUpdated:(id)object
{
    if ([self.delegate respondsToSelector:@selector(callsContainer:callUpdated:)]) {
        [self.delegate callsContainer:self callUpdated:object];
    }
}

- (void)basicContainerUpdate:(OCTBasicContainer *)container insertedSet:(NSIndexSet *)inserted removedSet:(NSIndexSet *)removed updatedSet:(NSIndexSet *)updated
{
    if ([self.delegate respondsToSelector:@selector(callsContainerUpdate:insertedSet:removedSet:updatedSet:)]) {
        [self.delegate callsContainerUpdate:self insertedSet:inserted removedSet:removed updatedSet:updated];
    }
}
@end
