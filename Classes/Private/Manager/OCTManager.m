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
#import "OCTSubmanagerUser+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerAvatars+Private.h"
#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"

@interface OCTManager () <OCTToxDelegate, OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (copy, nonatomic, readonly) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerUser *user;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerAvatars *avatars;
@property (strong, nonatomic, readwrite) OCTSubmanagerFiles *files;

@property (strong, nonatomic) OCTRealmManager *realmManager;

@property (strong, nonatomic, readonly) NSObject *toxSaveFileLock;

@end

@implementation OCTManager

#pragma mark -  Lifecycle

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
{
    return [self initWithConfiguration:configuration loadToxSaveFilePath:nil];
}

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                  loadToxSaveFilePath:(NSString *)toxSaveFilePath
{
    self = [super init];

    if (! self) {
        return nil;
    }

    [self validateConfiguration:configuration];

    NSString *savedDataPath = configuration.fileStorage.pathForToxSaveFile;

    if (toxSaveFilePath && [[NSFileManager defaultManager] fileExistsAtPath:toxSaveFilePath]) {
        [[NSFileManager defaultManager] moveItemAtPath:toxSaveFilePath toPath:savedDataPath error:nil];
    }

    _configuration = [configuration copy];

    NSData *savedData = nil;

    if ([[NSFileManager defaultManager] fileExistsAtPath:savedDataPath]) {
        savedData = [NSData dataWithContentsOfFile:savedDataPath];
    }

    _tox = [[OCTTox alloc] initWithOptions:configuration.options savedData:savedData error:nil];
    _tox.delegate = self;
    [_tox start];

    if (! savedData) {
        [self saveTox];
    }

    _realmManager = [[OCTRealmManager alloc] initWithDatabasePath:configuration.fileStorage.pathForDatabase];

    OCTSubmanagerUser *user = [OCTSubmanagerUser new];
    user.dataSource = self;
    _user = user;

    OCTSubmanagerFriends *friends = [OCTSubmanagerFriends new];
    friends.dataSource = self;
    [friends configure];
    _friends = friends;

    OCTSubmanagerChats *chats = [OCTSubmanagerChats new];
    chats.dataSource = self;
    _chats = chats;

    OCTSubmanagerFiles *files = [OCTSubmanagerFiles new];
    files.dataSource = self;
    _files = files;

    OCTSubmanagerAvatars *avatars = [OCTSubmanagerAvatars new];
    avatars.dataSource = self;
    _avatars = avatars;

    _toxSaveFileLock = [NSObject new];

    return self;
}

- (void)dealloc
{
    [self.tox stop];
}

#pragma mark -  Public

- (BOOL)bootstrapFromHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey error:(NSError **)error
{
    return [self.tox bootstrapFromHost:host port:port publicKey:publicKey error:error];
}

- (BOOL)addTCPRelayWithHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey error:(NSError **)error
{
    return [self.tox addTCPRelayWithHost:host port:port publicKey:publicKey error:error];
}

- (NSString *)exportToxSaveFile:(NSError **)error
{
    @synchronized(self.toxSaveFileLock) {
        NSString *savedDataPath = self.configuration.fileStorage.pathForToxSaveFile;
        NSString *tempPath = self.configuration.fileStorage.pathForTemporaryFilesDirectory;
        tempPath = [tempPath stringByAppendingPathComponent:[savedDataPath lastPathComponent]];

        if (! [[NSFileManager defaultManager] copyItemAtPath:savedDataPath toPath:tempPath error:error]) {
            return nil;
        }

        return tempPath;
    }
}

- (RBQFetchRequest *)fetchRequestForType:(OCTFetchRequestType)type withPredicate:(NSPredicate *)predicate
{
    return [self.realmManager fetchRequestForClass:[self classForFetchRequestType:type] withPredicate:predicate];
}

- (OCTObject *)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier forType:(OCTFetchRequestType)type
{
    return [self.realmManager objectWithUniqueIdentifier:uniqueIdentifier class:[self classForFetchRequestType:type]];
}

#pragma mark -  OCTSubmanagerDataSource

- (OCTTox *)managerGetTox
{
    return self.tox;
}

- (void)managerSaveTox
{
    return [self saveTox];
}

- (OCTRealmManager *)managerGetRealmManager
{
    return self.realmManager;
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

- (BOOL)respondsToSelector:(SEL)aSelector
{
    id submanager = [self forwardingTargetForSelector:aSelector];

    if (submanager) {
        return YES;
    }

    return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    struct objc_method_description description = protocol_getMethodDescription(@protocol(OCTToxDelegate), aSelector, NO, YES);

    if (description.name == NULL) {
        // We forward methods only from OCTToxDelegate protocol.
        return nil;
    }

    NSArray *submanagers = @[
        self.user,
        self.friends,
        self.chats,
        self.files,
        self.avatars,
    ];

    for (id delegate in submanagers) {
        if ([delegate respondsToSelector:aSelector]) {
            return delegate;
        }
    }

    return nil;
}

- (void)saveTox
{
    @synchronized(self.toxSaveFileLock) {
        NSString *savedDataPath = self.configuration.fileStorage.pathForToxSaveFile;

        NSData *data = [self.tox save];

        NSError *error;

        if (! [data writeToFile:savedDataPath options:0 error:&error]) {
            @throw [NSException exceptionWithName:@"saveToxException"
                                           reason:error.debugDescription
                                         userInfo:@{ @"NSError" : error }];
        }
    }
}

- (Class)classForFetchRequestType:(OCTFetchRequestType)type
{
    switch (type) {
        case OCTFetchRequestTypeFriend:
            return [OCTFriend class];
        case OCTFetchRequestTypeFriendRequest:
            return [OCTFriendRequest class];
        case OCTFetchRequestTypeChat:
            return [OCTChat class];
        case OCTFetchRequestTypeMessageAbstract:
            return [OCTMessageAbstract class];
    }
}

@end
