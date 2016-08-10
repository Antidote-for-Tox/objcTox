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
#import "OCTToxEncryptSave.h"
#import "OCTManagerConfiguration.h"
#import "OCTManagerFactory.h"
#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTSubmanagerCalls+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerDNS+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerObjects+Private.h"
#import "OCTSubmanagerUser+Private.h"
#import "OCTRealmManager.h"

@interface OCTManager () <OCTToxDelegate, OCTSubmanagerDataSource>

@property (copy, nonatomic, readonly) OCTManagerConfiguration *currentConfiguration;

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (strong, nonatomic, readonly) NSObject *toxSaveFileLock;

@property (strong, nonatomic) OCTToxEncryptSave *encryptSave;

@property (strong, nonatomic, readonly) OCTRealmManager *realmManager;
@property (strong, atomic) NSNotificationCenter *notificationCenter;

@property (strong, nonatomic, readwrite) OCTSubmanagerBootstrap *bootstrap;
@property (strong, nonatomic, readwrite) OCTSubmanagerCalls *calls;
@property (strong, nonatomic, readwrite) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerDNS *dns;
@property (strong, nonatomic, readwrite) OCTSubmanagerFiles *files;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerObjects *objects;
@property (strong, nonatomic, readwrite) OCTSubmanagerUser *user;

@end

@implementation OCTManager

#pragma mark -  Class methods

+ (BOOL)isToxSaveEncryptedAtPath:(NSString *)path
{
    NSData *savedData = [OCTManager getSavedDataFromPath:path];

    if (! savedData) {
        return NO;
    }

    return [OCTToxEncryptSave isDataEncrypted:savedData];
}

#pragma mark -  Lifecycle

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                                  tox:(OCTTox *)tox
                       toxEncryptSave:(OCTToxEncryptSave *)toxEncryptSave
                         realmManager:(OCTRealmManager *)realmManager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _currentConfiguration = [configuration copy];

    _tox = tox;
    _tox.delegate = self;
    _toxSaveFileLock = [NSObject new];

    _encryptSave = toxEncryptSave;

    _realmManager = realmManager;
    _notificationCenter = [[NSNotificationCenter alloc] init];

    [_tox start];
    [self saveTox];

    [self createSubmanagers];

    return self;
}

+ (void)managerWithConfiguration:(OCTManagerConfiguration *)configuration
                     toxPassword:(nullable NSString *)toxPassword
                databasePassword:(NSString *)databasePassword
                    successBlock:(void (^)(OCTManager *manager))successBlock
                    failureBlock:(void (^)(NSError *error))failureBlock
{
    return [OCTManagerFactory managerWithConfiguration:configuration
                                           toxPassword:toxPassword
                                      databasePassword:databasePassword
                                          successBlock:successBlock
                                          failureBlock:failureBlock];
}

- (void)dealloc
{
    [self killSubmanagers];
    [self.tox stop];
}

#pragma mark -  Public

- (OCTManagerConfiguration *)configuration
{
    return [self.currentConfiguration copy];
}

- (NSString *)exportToxSaveFile:(NSError **)error
{
    @synchronized(self.toxSaveFileLock) {
        NSString *savedDataPath = self.currentConfiguration.fileStorage.pathForToxSaveFile;
        NSString *tempPath = self.currentConfiguration.fileStorage.pathForTemporaryFilesDirectory;
        tempPath = [tempPath stringByAppendingPathComponent:[savedDataPath lastPathComponent]];

        NSFileManager *fileManager = [NSFileManager defaultManager];

        if ([fileManager fileExistsAtPath:tempPath]) {
            [fileManager removeItemAtPath:tempPath error:error];
        }

        if (! [fileManager copyItemAtPath:savedDataPath toPath:tempPath error:error]) {
            return nil;
        }

        return tempPath;
    }
}

- (BOOL)changeToxPassword:(nullable NSString *)newPassword oldPassword:(nullable NSString *)oldPassword
{
    NSString *toxFilePath = self.currentConfiguration.fileStorage.pathForToxSaveFile;

    if (! [self isDataAtPath:toxFilePath encryptedWithPassword:oldPassword]) {
        return NO;
    }

    __block BOOL result = NO;

    @synchronized(self.toxSaveFileLock) {
        if (newPassword) {
            // Passing nil as tox data as we are setting new password.
            self.encryptSave = [[OCTToxEncryptSave alloc] initWithPassphrase:newPassword toxData:nil error:nil];
            result = (self.encryptSave != 0);
        }
        else {
            self.encryptSave = nil;
            result = YES;
        }
    }

    [self saveTox];

    return result;
}

- (BOOL)changeDatabasePassword:(NSString *)newPassword oldPassword:(NSString *)oldPassword
{
    NSParameterAssert(newPassword);
    NSParameterAssert(oldPassword);

    NSString *encryptedKeyPath = self.currentConfiguration.fileStorage.pathForDatabaseEncryptionKey;
    NSData *encryptedKey = [NSData dataWithContentsOfFile:encryptedKeyPath];

    if (! encryptedKey) {
        return NO;
    }

    NSData *key = [OCTToxEncryptSave decryptData:encryptedKey withPassphrase:oldPassword error:nil];

    if (! key) {
        return NO;
    }

    NSData *newEncryptedKey = [OCTToxEncryptSave encryptData:key withPassphrase:newPassword error:nil];

    if (! newEncryptedKey) {
        return NO;
    }

    return [newEncryptedKey writeToFile:encryptedKeyPath options:NSDataWritingAtomic error:nil];
}

#pragma mark -  OCTSubmanagerDataSource

- (OCTTox *)managerGetTox
{
    return self.tox;
}

- (BOOL)managerIsToxConnected
{
    return (self.user.connectionStatus != OCTToxConnectionStatusNone);
}

- (void)managerSaveTox
{
    return [self saveTox];
}

- (OCTRealmManager *)managerGetRealmManager
{
    return self.realmManager;
}

- (id<OCTFileStorageProtocol>)managerGetFileStorage
{
    return self.currentConfiguration.fileStorage;
}

- (NSNotificationCenter *)managerGetNotificationCenter
{
    return self.notificationCenter;
}

#pragma mark -  Private

+ (NSData *)getSavedDataFromPath:(NSString *)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ?
           ([NSData dataWithContentsOfFile:path]) :
           nil;
}

- (BOOL)isDataAtPath:(NSString *)path encryptedWithPassword:(NSString *)password
{
    NSData *savedData = [OCTManager getSavedDataFromPath:path];

    if (! savedData) {
        return NO;
    }

    if ([OCTToxEncryptSave isDataEncrypted:savedData]) {
        return [OCTToxEncryptSave decryptData:savedData withPassphrase:password error:nil] != nil;
    }
    else {
        return password == nil;
    }

    return NO;
}

- (void)createSubmanagers
{
    _bootstrap = [self createSubmanagerWithClass:[OCTSubmanagerBootstrap class]];
    _chats = [self createSubmanagerWithClass:[OCTSubmanagerChats class]];
    _dns = [self createSubmanagerWithClass:[OCTSubmanagerDNS class]];
    _files = [self createSubmanagerWithClass:[OCTSubmanagerFiles class]];
    _friends = [self createSubmanagerWithClass:[OCTSubmanagerFriends class]];
    _objects = [self createSubmanagerWithClass:[OCTSubmanagerObjects class]];
    _user = [self createSubmanagerWithClass:[OCTSubmanagerUser class]];

    OCTSubmanagerCalls *calls = [[OCTSubmanagerCalls alloc] initWithTox:_tox];
    calls.dataSource = self;
    _calls = calls;
    [_calls setupWithError:nil];
}

- (void)killSubmanagers
{
    self.bootstrap = nil;
    self.calls = nil;
    self.chats = nil;
    self.dns = nil;
    self.files = nil;
    self.friends = nil;
    self.objects = nil;
    self.user = nil;
}

- (id<OCTSubmanagerProtocol>)createSubmanagerWithClass:(Class)class
{
    id<OCTSubmanagerProtocol> submanager = [[class alloc] init];
    submanager.dataSource = self;

    if ([submanager respondsToSelector:@selector(configure)]) {
        [submanager configure];
    }

    return submanager;
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
        self.bootstrap,
        self.chats,
        self.dns,
        self.files,
        self.friends,
        self.objects,
        self.user,
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
        void (^throwException)(NSError *) = ^(NSError *error) {
            NSDictionary *userInfo = nil;

            if (error) {
                userInfo = @{ @"NSError" : error };
            }

            @throw [NSException exceptionWithName:@"saveToxException" reason:error.debugDescription userInfo:userInfo];
        };

        NSData *data = [self.tox save];

        NSError *error;

        if (self.encryptSave) {
            data = [self.encryptSave encryptData:data error:&error];

            if (! data) {
                throwException(error);
            }
        }

        if (! [data writeToFile:self.currentConfiguration.fileStorage.pathForToxSaveFile options:NSDataWritingAtomic error:&error]) {
            throwException(error);
        }
    }
}

@end
