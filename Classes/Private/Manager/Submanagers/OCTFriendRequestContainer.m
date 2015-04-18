//
//  OCTFriendRequestContainer.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 17.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendRequestContainer.h"
#import "OCTFriendRequestContainer+Private.h"
#import "OCTManagerConstants.h"
#import "OCTBasicContainer.h"

@interface OCTFriendRequestContainer()

@property (strong, nonatomic) OCTBasicContainer *container;

@end

@implementation OCTFriendRequestContainer

#pragma mark -  Lifecycle

- (instancetype)initWithFriendRequestsArray:(NSArray *)array
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.container = [[OCTBasicContainer alloc] initWithObjects:array
                                         updateNotificationName:kOCTFriendRequestContainerUpdateNotification];
    [self.container setComparatorForCurrentSort:^NSComparisonResult (OCTFriendRequest *first, OCTFriendRequest *second) {
        return [first.publicKey compare:second.publicKey];
    } sendNotification:NO];

    return self;
}

#pragma mark -  Public

- (NSUInteger)requestsCount
{
    return [self.container count];
}

- (OCTFriendRequest *)requestAtIndex:(NSUInteger)index
{
    return [self.container objectAtIndex:index];
}

#pragma mark -  Private category

- (void)addRequest:(OCTFriendRequest *)request
{
    [self.container addObject:request];
}

- (void)removeRequest:(OCTFriendRequest *)request
{
    [self.container removeObject:request];
}

@end
