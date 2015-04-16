//
//  OCTManagerConstants.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

/**
 * Sort type for FriendsContainer.
 */
typedef NS_ENUM(NSUInteger, OCTFriendsSort) {
    /**
     * Sort by friend name. In case if name will be nil, friends will be sorted by publicKey.
     */
    OCTFriendsSortByName = 0,

    /**
     * Sort by status. Within groups friends will be sorted by name.
     * - online
     * - away
     * - busy
     * - offline
     */
    OCTFriendsSortByStatus,
};

typedef NS_ENUM(NSUInteger, OCTMessageFileType) {
    /**
     * File is incoming and is waiting confirmation of user to be downloaded.
     * Please start loading or cancel it with <<placeholder>> method.
     */
    OCTMessageFileTypeWaitingConfirmation,

    /**
     * File is downloading or uploading.
     */
    OCTMessageFileTypeLoading,

    /**
     * Downloading or uploading of file is paused.
     */
    OCTMessageFileTypePaused,

    /**
     * Downloading or uploading of file was canceled.
     */
    OCTMessageFileTypeCanceled,

    /**
     * File is fully loaded.
     * In case of incoming file now it can be shown to user.
     */
    OCTMessageFileTypeReady,
};

extern NSString *const kOCTContainerUpdateKeyInsertedSet;
extern NSString *const kOCTContainerUpdateKeyRemovedSet;
extern NSString *const kOCTContainerUpdateKeyUpdatedSet;

