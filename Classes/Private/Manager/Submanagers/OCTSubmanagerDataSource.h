//
//  OCTSubmanagerDataSource.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCTTox;
@class OCTRealmManager;
@protocol OCTFileStorageProtocol;

/**
 * Notification is send when connection status of friend has changed.
 *
 * - object OCTFriend whose status has changed.
 * - userInfo nil
 */
static NSString *const kOCTFriendConnectionStatusChangeNotification = @"kOCTFriendConnectionStatusChangeNotification";

/**
 * Notification is send on user avatar update.
 *
 * - object nil
 * - userInfo nil
 */
static NSString *const kOCTUserAvatarWasUpdatedNotification = @"kOCTUserAvatarWasUpdatedNotification";

@protocol OCTSubmanagerDataSource <NSObject>

- (OCTTox *)managerGetTox;
- (BOOL)managerIsToxConnected;
- (void)managerSaveTox;
- (OCTRealmManager *)managerGetRealmManager;
- (id<OCTFileStorageProtocol>)managerGetFileStorage;
- (NSNotificationCenter *)managerGetNotificationCenter;

@end
