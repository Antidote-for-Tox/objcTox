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
#import "OCTToxEncryptSaveConstants.h"
#import "OCTManagerConfiguration.h"
#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTSubmanagerCalls+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerDNS+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerObjects+Private.h"
#import "OCTSubmanagerUser+Private.h"
#import "OCTRealmManager.h"

typedef NS_ENUM(NSInteger, OCTDecryptionErrorFileType) {
    OCTDecryptionErrorFileTypeDatabaseKey,
    OCTDecryptionErrorFileTypeToxFile,
};


static const NSUInteger kEncryptedKeyLength = 64;

@interface OCTManager () <OCTToxDelegate, OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (copy, nonatomic, readonly) OCTManagerConfiguration *currentConfiguration;

@property (strong, nonatomic, readwrite) OCTSubmanagerBootstrap *bootstrap;
@property (strong, nonatomic, readwrite) OCTSubmanagerCalls *calls;
@property (strong, nonatomic, readwrite) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerDNS *dns;
@property (strong, nonatomic, readwrite) OCTSubmanagerFiles *files;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerObjects *objects;
@property (strong, nonatomic, readwrite) OCTSubmanagerUser *user;

@property (strong, nonatomic) OCTRealmManager *realmManager;

@property (strong, nonatomic, readonly) NSObject *toxSaveFileLock;

@property (strong, atomic) NSNotificationCenter *notificationCenter;

@property (strong, nonatomic) OCTToxEncryptSave *encryptSave;

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

- (nullable instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                                   toxPassword:(nullable NSString *)toxPassword
                              databasePassword:(NSString *)databasePassword
                                         error:(NSError *__nullable *__nullable)error
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _currentConfiguration = [configuration copy];

    BOOL result =
        [self validateConfiguration:configuration] &&
        [self createRealmManagerWithDatabasePassword:databasePassword error:error] &&
        [self importToxSaveIfNeeded:error] &&
        [self createToxWithPassword:toxPassword error:error] &&
        [self createNotificationCenter] &&
        [self createSubmanagers];

    return result ? self : nil;
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

    // Passing nil as tox data as we are setting new passphrase.
    BOOL result = [self createEncryptSaveWithPassphrase:newPassword toxData:nil];

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

- (BOOL)createEncryptSaveWithPassphrase:(NSString *)passphrase toxData:(NSData *)toxData
{
    @synchronized(self.toxSaveFileLock) {
        if (passphrase) {
            self.encryptSave = [[OCTToxEncryptSave alloc] initWithPassphrase:passphrase toxData:toxData error:nil];
            return (self.encryptSave != 0);
        }
        else {
            self.encryptSave = nil;
            return YES;
        }
    }
}

- (BOOL)validateConfiguration:(OCTManagerConfiguration *)configuration
{
    NSParameterAssert(configuration.fileStorage);
    NSParameterAssert(configuration.fileStorage.pathForDownloadedFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForUploadedFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForTemporaryFilesDirectory);

    NSParameterAssert(configuration.options);

    return YES;
}

- (BOOL)createNotificationCenter
{
    _notificationCenter = [[NSNotificationCenter alloc] init];

    return YES;
}

- (BOOL)importToxSaveIfNeeded:(NSError **)error
{
    BOOL result = YES;

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (_currentConfiguration.importToxSaveFromPath && [fileManager fileExistsAtPath:_currentConfiguration.importToxSaveFromPath]) {
        result = [fileManager copyItemAtPath:_currentConfiguration.importToxSaveFromPath
                                      toPath:_currentConfiguration.fileStorage.pathForToxSaveFile
                                       error:nil];
    }

    if (! result) {
        [self fillError:error withInitErrorCode:OCTManagerInitErrorCannotImportToxSave];
    }

    return result;
}

- (BOOL)migrateToEncryptedDatabase:(NSString *)databasePath
                 encryptionKeyPath:(NSString *)encryptionKeyPath
                      withPassword:(NSString *)password
                             error:(NSError **)error
{
    NSParameterAssert(databasePath);
    NSParameterAssert(encryptionKeyPath);
    NSParameterAssert(password);

    if ([[NSFileManager defaultManager] fileExistsAtPath:encryptionKeyPath]) {
        if (error) {
            *error = [NSError errorWithDomain:kOCTManagerErrorDomain code:100 userInfo:@{
                          NSLocalizedDescriptionKey : @"Cannot migrate unencrypted database to encrypted",
                          NSLocalizedFailureReasonErrorKey : @"Database is already encrypted",
                      }];
        }
        return NO;
    }

    NSString *tempKeyPath = [encryptionKeyPath stringByAppendingPathExtension:@"tmp"];

    if (! [self createEncryptedKeyAtPath:tempKeyPath withPassword:password]) {
        if (error) {
            *error = [NSError errorWithDomain:kOCTManagerErrorDomain code:101 userInfo:@{
                          NSLocalizedDescriptionKey : @"Cannot migrate unencrypted database to encrypted",
                          NSLocalizedFailureReasonErrorKey : @"Cannot create encryption key",
                      }];
        }
        return NO;
    }

    NSData *encryptedKey = [NSData dataWithContentsOfFile:tempKeyPath];

    if (! encryptedKey) {
        if (error) {
            *error = [NSError errorWithDomain:kOCTManagerErrorDomain code:102 userInfo:@{
                          NSLocalizedDescriptionKey : @"Cannot migrate unencrypted database to encrypted",
                          NSLocalizedFailureReasonErrorKey : @"Cannot find encryption key",
                      }];
        }
        return NO;
    }

    NSData *key = [OCTToxEncryptSave decryptData:encryptedKey withPassphrase:password error:error];

    if (! key) {
        return NO;
    }

    if (! [OCTRealmManager migrateToEncryptedDatabase:databasePath encryptionKey:key error:error]) {
        return NO;
    }

    if (! [[NSFileManager defaultManager] moveItemAtPath:tempKeyPath toPath:encryptionKeyPath error:error]) {
        return NO;
    }

    return YES;
}


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

- (NSData *)decryptSavedDataIfNeeded:(NSData *)data error:(NSError **)error wasDecryptError:(BOOL *)wasDecryptError
{
    if (! data || ! _encryptSave) {
        return data;
    }

    NSError *decryptError = nil;

    NSData *result = [_encryptSave decryptData:data error:&decryptError];

    if (result) {
        return result;
    }

    *wasDecryptError = YES;
    [self fillError:error withDecryptionError:decryptError.code fileType:OCTDecryptionErrorFileTypeToxFile];

    return nil;
}

- (BOOL)createToxWithPassword:(NSString *)password error:(NSError **)error
{
    NSData *savedData = [OCTManager getSavedDataFromPath:_currentConfiguration.fileStorage.pathForToxSaveFile];

    if (! [self createEncryptSaveWithPassphrase:password toxData:savedData]) {
        [self fillError:error withInitErrorCode:OCTManagerInitErrorPassphraseFailed];
        return YES;
    }

    BOOL wasDecryptError = NO;
    savedData = [self decryptSavedDataIfNeeded:savedData error:error wasDecryptError:&wasDecryptError];

    if (wasDecryptError) {
        return NO;
    }

    return [self createToxWithSavedData:savedData error:error];
}

- (BOOL)createToxWithSavedData:(NSData *)savedData error:(NSError **)error
{
    NSError *toxError = nil;

    _tox = [[OCTTox alloc] initWithOptions:_currentConfiguration.options savedData:savedData error:&toxError];

    if (_tox) {
        _toxSaveFileLock = [NSObject new];
        _tox.delegate = self;
        [_tox start];

        if (! savedData) {
            // Tox was created for the first time, save it.
            [self saveTox];
        }

        return YES;
    }

    OCTToxErrorInitCode code = toxError.code;

    switch (code) {
        case OCTToxErrorInitCodeUnknown:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxUnknown];
            break;
        case OCTToxErrorInitCodeMemoryError:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxMemoryError];
            break;
        case OCTToxErrorInitCodePortAlloc:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxPortAlloc];
            break;
        case OCTToxErrorInitCodeProxyBadType:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxProxyBadType];
            break;
        case OCTToxErrorInitCodeProxyBadHost:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxProxyBadHost];
            break;
        case OCTToxErrorInitCodeProxyBadPort:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxProxyBadPort];
            break;
        case OCTToxErrorInitCodeProxyNotFound:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxProxyNotFound];
            break;
        case OCTToxErrorInitCodeEncrypted:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxEncrypted];
            break;
        case OCTToxErrorInitCodeLoadBadFormat:
            [self fillError:error withInitErrorCode:OCTManagerInitErrorCreateToxBadFormat];
            break;
    }

    return NO;
}

- (BOOL)createRealmManagerWithDatabasePassword:(NSString *)databasePassword error:(NSError **)error
{
    NSString *databasePath = _currentConfiguration.fileStorage.pathForDatabase;
    NSString *encryptedKeyPath = _currentConfiguration.fileStorage.pathForDatabaseEncryptionKey;

    BOOL databaseExists = [[NSFileManager defaultManager] fileExistsAtPath:databasePath];
    BOOL encryptedKeyExists = [[NSFileManager defaultManager] fileExistsAtPath:encryptedKeyPath];

    if (! databaseExists && ! encryptedKeyExists) {
        // First run, create key and database.
        if (! [self createEncryptedKeyAtPath:encryptedKeyPath withPassword:databasePassword]) {
            [self fillError:error withInitErrorCode:OCTManagerInitErrorDatabaseKeyCannotCreateKey];
            return NO;
        }
    }

    if (databaseExists && ! encryptedKeyExists) {
        // It seems that we found old unencrypted database, let's migrate to encrypted one.
        NSError *migrationError;

        BOOL result = [self migrateToEncryptedDatabase:databasePath
                                     encryptionKeyPath:encryptedKeyPath
                                          withPassword:databasePassword
                                                 error:&migrationError];

        if (! result) {
            if (error) {
                *error = [NSError errorWithDomain:kOCTManagerErrorDomain code:OCTManagerInitErrorDatabaseKeyMigrationToEncryptedFailed userInfo:@{
                              NSLocalizedDescriptionKey : migrationError.localizedDescription,
                              NSLocalizedFailureReasonErrorKey : migrationError.localizedFailureReason,
                          }];
            }

            return NO;
        }
    }

    NSData *encryptedKey = [NSData dataWithContentsOfFile:encryptedKeyPath];

    if (! encryptedKey) {
        [self fillError:error withInitErrorCode:OCTManagerInitErrorDatabaseKeyCannotReadKey];
        return NO;
    }

    NSError *decryptError;
    NSData *key = [OCTToxEncryptSave decryptData:encryptedKey withPassphrase:databasePassword error:&decryptError];

    if (! key) {
        [self fillError:error withDecryptionError:decryptError.code fileType:OCTDecryptionErrorFileTypeDatabaseKey];
        return NO;
    }

    _realmManager = [[OCTRealmManager alloc] initWithDatabaseFileURL:[NSURL fileURLWithPath:databasePath]
                                                       encryptionKey:key];

    return YES;
}

- (BOOL)createEncryptedKeyAtPath:(NSString *)path withPassword:(NSString *)password
{
    NSMutableData *key = [NSMutableData dataWithLength:kEncryptedKeyLength];
    SecRandomCopyBytes(kSecRandomDefault, key.length, (uint8_t *)key.mutableBytes);

    NSData *encryptedKey = [OCTToxEncryptSave encryptData:key withPassphrase:password error:nil];

    return [encryptedKey writeToFile:path options:NSDataWritingAtomic error:nil];
}

- (BOOL)createSubmanagers
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

    return YES;
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

- (BOOL)fillError:(NSError **)error withDecryptionError:(OCTToxEncryptSaveDecryptionError)code fileType:(OCTDecryptionErrorFileType)fileType
{
    if (! error) {
        return NO;
    }

    NSDictionary *mapping;

    switch (fileType) {
        case OCTDecryptionErrorFileTypeDatabaseKey:
            mapping = @{
                @(OCTToxEncryptSaveDecryptionErrorNull) : @(OCTManagerInitErrorDatabaseKeyDecryptNull),
                @(OCTToxEncryptSaveDecryptionErrorBadFormat) : @(OCTManagerInitErrorDatabaseKeyDecryptBadFormat),
                @(OCTToxEncryptSaveDecryptionErrorFailed) : @(OCTManagerInitErrorDatabaseKeyDecryptFailed),
            };
            break;
        case OCTDecryptionErrorFileTypeToxFile:
            mapping = @{
                @(OCTToxEncryptSaveDecryptionErrorNull) : @(OCTManagerInitErrorToxFileDecryptNull),
                @(OCTToxEncryptSaveDecryptionErrorBadFormat) : @(OCTManagerInitErrorToxFileDecryptBadFormat),
                @(OCTToxEncryptSaveDecryptionErrorFailed) : @(OCTManagerInitErrorToxFileDecryptFailed),
            };
            break;
    }

    OCTManagerInitError initErrorCode = [mapping[@(code)] integerValue];
    [self fillError:error withInitErrorCode:initErrorCode];

    return YES;
}

- (BOOL)fillError:(NSError **)error withInitErrorCode:(OCTManagerInitError)code
{
    if (! error) {
        return NO;
    }

    NSString *failureReason = nil;

    switch (code) {
        case OCTManagerInitErrorPassphraseFailed:
            failureReason = @"Cannot create symmetric key from given passphrase.";
            break;
        case OCTManagerInitErrorCannotImportToxSave:
            failureReason = @"Cannot copy tox save at `importToxSaveFromPath` path.";
            break;
        case OCTManagerInitErrorDatabaseKeyCannotCreateKey:
            failureReason = @"Cannot create encryption key.";
            break;
        case OCTManagerInitErrorDatabaseKeyCannotReadKey:
            failureReason = @"Cannot read encryption key.";
            break;
        case OCTManagerInitErrorDatabaseKeyMigrationToEncryptedFailed:
            // Nothing to do here, this error will be created elsewhere.
            break;
        case OCTManagerInitErrorDatabaseKeyDecryptNull:
            failureReason = @"Cannot decrypt database key file. Some input data was empty.";
            break;
        case OCTManagerInitErrorDatabaseKeyDecryptBadFormat:
            failureReason = @"Cannot decrypt database key file. Data has bad format.";
            break;
        case OCTManagerInitErrorDatabaseKeyDecryptFailed:
            failureReason = @"Cannot decrypt database key file. The encrypted byte array could not be decrypted. Either the data was corrupt or the password/key was incorrect.";
            break;
        case OCTManagerInitErrorToxFileDecryptNull:
            failureReason = @"Cannot decrypt tox save file. Some input data was empty.";
            break;
        case OCTManagerInitErrorToxFileDecryptBadFormat:
            failureReason = @"Cannot decrypt tox save file. Data has bad format.";
            break;
        case OCTManagerInitErrorToxFileDecryptFailed:
            failureReason = @"Cannot decrypt tox save file. The encrypted byte array could not be decrypted. Either the data was corrupt or the password/key was incorrect.";
            break;
        case OCTManagerInitErrorCreateToxUnknown:
            failureReason = @"Cannot create tox. Unknown error occurred.";
            break;
        case OCTManagerInitErrorCreateToxMemoryError:
            failureReason = @"Cannot create tox. Was unable to allocate enough memory to store the internal structures for the Tox object.";
            break;
        case OCTManagerInitErrorCreateToxPortAlloc:
            failureReason = @"Cannot create tox. Was unable to bind to a port.";
            break;
        case OCTManagerInitErrorCreateToxProxyBadType:
            failureReason = @"Cannot create tox. Proxy type was invalid.";
            break;
        case OCTManagerInitErrorCreateToxProxyBadHost:
            failureReason = @"Cannot create tox. proxyAddress had an invalid format or was nil (while proxyType was set).";
            break;
        case OCTManagerInitErrorCreateToxProxyBadPort:
            failureReason = @"Cannot create tox. Proxy port was invalid.";
            break;
        case OCTManagerInitErrorCreateToxProxyNotFound:
            failureReason = @"Cannot create tox. The proxy host passed could not be resolved.";
            break;
        case OCTManagerInitErrorCreateToxEncrypted:
            failureReason = @"Cannot create tox. The saved data to be loaded contained an encrypted save.";
            break;
        case OCTManagerInitErrorCreateToxBadFormat:
            failureReason = @"Cannot create tox. Data has bad format.";
            break;
    }

    *error = [NSError errorWithDomain:kOCTManagerErrorDomain code:code userInfo:@{
                  NSLocalizedDescriptionKey : @"Cannot create OCTManager",
                  NSLocalizedFailureReasonErrorKey : failureReason
              }];

    return YES;
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
