//
//  OCTSubmanagerUser.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerUser+Private.h"
#import "OCTTox.h"
#import "OCTManagerConstants.h"
#import "OCTRealmManager.h"
#import "OCTSettingsStorageObject.h"

@interface OCTSubmanagerUser ()

@end

@implementation OCTSubmanagerUser
@synthesize dataSource = _dataSource;

#pragma mark -  Properties

- (OCTToxConnectionStatus)connectionStatus
{
    return [self.dataSource managerGetTox].connectionStatus;
}

- (NSString *)userAddress
{
    return [self.dataSource managerGetTox].userAddress;
}

- (NSString *)publicKey
{
    return [self.dataSource managerGetTox].publicKey;
}

#pragma mark -  Public

- (OCTToxNoSpam)nospam
{
    return [self.dataSource managerGetTox].nospam;
}

- (void)setNospam:(OCTToxNoSpam)nospam
{
    [self.dataSource managerGetTox].nospam = nospam;
    [self.dataSource managerSaveTox];
}

- (OCTToxUserStatus)userStatus
{
    return [self.dataSource managerGetTox].userStatus;
}

- (void)setUserStatus:(OCTToxUserStatus)userStatus
{
    [self.dataSource managerGetTox].userStatus = userStatus;
    [self.dataSource managerSaveTox];
}

- (BOOL)setUserName:(NSString *)name error:(NSError **)error
{
    if ([[self.dataSource managerGetTox] setNickname:name error:error]) {
        [self.dataSource managerSaveTox];
        return YES;
    }

    return NO;
}

- (NSString *)userName
{
    return [[self.dataSource managerGetTox] userName];
}

- (BOOL)setUserStatusMessage:(NSString *)statusMessage error:(NSError **)error
{
    if ([[self.dataSource managerGetTox] setUserStatusMessage:statusMessage error:error]) {
        [self.dataSource managerSaveTox];
        return YES;
    }

    return NO;
}

- (NSString *)userStatusMessage
{
    return [[self.dataSource managerGetTox] userStatusMessage];
}

- (BOOL)setUserAvatar:(NSData *)avatar error:(NSError **)error
{
    if (avatar && (avatar.length > kOCTManagerMaxAvatarSize)) {
        if (error) {
            *error = [NSError errorWithDomain:kOCTManagerErrorDomain
                                         code:OCTSetUserAvatarErrorTooBig
                                     userInfo:@{
                          NSLocalizedDescriptionKey : @"Cannot set user avatar",
                          NSLocalizedFailureReasonErrorKey : @"Avatar is too big",
                      }];
        }
        return NO;
    }

    OCTRealmManager *realmManager = self.dataSource.managerGetRealmManager;

    [realmManager updateObject:realmManager.settingsStorage withBlock:^(OCTSettingsStorageObject *object) {
        object.userAvatarData = avatar;
    }];

    [self.dataSource.managerGetNotificationCenter postNotificationName:kOCTUserAvatarWasUpdatedNotification object:nil];

    return YES;
}

- (NSData *)userAvatar
{
    return self.dataSource.managerGetRealmManager.settingsStorage.userAvatarData;
}

#pragma mark -  OCTToxDelegate

- (void)tox:(OCTTox *)tox connectionStatus:(OCTToxConnectionStatus)connectionStatus
{
    if (connectionStatus != OCTToxConnectionStatusNone) {
        [self.dataSource managerSaveTox];
    }

    [self.delegate submanagerUser:self connectionStatusUpdate:connectionStatus];
}

@end
