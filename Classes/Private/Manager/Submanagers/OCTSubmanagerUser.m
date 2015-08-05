//
//  OCTSubmanagerUser.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerUser+Private.h"
#import "OCTTox.h"

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

#pragma mark -  OCTToxDelegate

- (void)tox:(OCTTox *)tox connectionStatus:(OCTToxConnectionStatus)connectionStatus
{
    [self.delegate OCTSubmanagerUser:self connectionStatusUpdate:connectionStatus];
}

@end
