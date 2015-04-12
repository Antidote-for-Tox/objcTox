//
//  OCTManager.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 06.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <objc/runtime.h>

#import "OCTManager.h"
#import "OCTTox.h"
#import "OCTSubmanagerFriends.h"
#import "OCTSubmanagerAvatars.h"

@interface OCTManager() <OCTToxDelegate, OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (copy, nonatomic, readonly) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerAvatars *avatars;

@end

@implementation OCTManager

#pragma mark -  Lifecycle

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
{
    self = [super init];

    if (! self) {
        return nil;
    }

    [self validateConfiguration:configuration];

    _configuration = [configuration copy];

    NSData *savedData = nil;
    NSString *savedDataPath = configuration.fileStorage.pathForToxSaveFile;

    if ([[NSFileManager defaultManager] fileExistsAtPath:savedDataPath]) {
        savedData = [NSData dataWithContentsOfFile:savedDataPath];
    }

    _tox = [[OCTTox alloc] initWithOptions:configuration.options savedData:savedData error:nil];
    _tox.delegate = self;

    OCTSubmanagerFriends *friends = [OCTSubmanagerFriends new];
    friends.dataSource = self;
    [friends configure];
    _friends = friends;

    OCTSubmanagerAvatars *avatars = [OCTSubmanagerAvatars new];
    avatars.dataSource = self;
    _avatars = avatars;

    return self;
}

#pragma mark -  OCTSubmanagerDataSource

- (OCTTox *)managerGetTox
{
    return self.tox;
}

- (id<OCTSettingsStorageProtocol>)managerGetSettingsStorage
{
    return self.configuration.settingsStorage;
}

- (id<OCTFileStorageProtocol>)managerGetFileStorage
{
    return self.configuration.fileStorage;
}

#pragma mark -  Private

- (void)validateConfiguration:(OCTManagerConfiguration *)configuration
{
    NSParameterAssert(configuration.settingsStorage);

    NSParameterAssert(configuration.fileStorage);
    NSParameterAssert(configuration.fileStorage.pathForDownloadedFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForUploadedFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForTemporaryFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForAvatarsDirectory);

    NSParameterAssert(configuration.options);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    struct objc_method_description description = protocol_getMethodDescription(@protocol(OCTToxDelegate), aSelector, NO, YES);

    if (description.name == NULL) {
        // We forward methods only from OCTToxDelegate protocol.
        return nil;
    }

    NSArray *submanagers = @[
        self.avatars,
        self.friends,
    ];

    for (id delegate in submanagers) {
        if ([delegate respondsToSelector:aSelector]) {
            return delegate;
        }
    }

    return nil;
}

@end
