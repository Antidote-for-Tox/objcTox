//
//  OCTSubmanagerFriends.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFriends.h"
#import "OCTFriendsContainer.h"

@interface OCTSubmanagerFriends() <OCTFriendsContainerDataSource>

@property (strong, nonatomic) OCTFriendsContainer *container;

@end

@implementation OCTSubmanagerFriends
@synthesize container = _container;

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _container = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];
    _container.dataSource = self;

    return self;
}

#pragma mark -  Public

- (void)configure
{
    [self.container configure];
}

#pragma mark -  OCTFriendsContainerDataSource

- (id<OCTSettingsStorageProtocol>)friendsContainerGetSettingsStorage
{
    return [self.dataSource managerGetSettingsStorage];
}

@end
