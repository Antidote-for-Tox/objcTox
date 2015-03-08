//
//  OCTFileStorageProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OCTFileStorageProtocol <NSObject>

@required

/**
 * Returns path where all downloaded files will be stored.
 *
 * @return Full path to the directory with downloaded files.
 */
@property (readonly) NSString *pathForDownloadedFilesDirectory;

/**
 * Returns path where all uploaded files will be stored.
 *
 * @return Full path to the directory with uploaded files.
 */
@property (readonly) NSString *pathForUploadedFilesDirectory;

/**
 * Returns path where temporary files will be stored. This directory can be cleaned on relaunch of app.
 * You can use NSTemporaryDirectory() here.
 *
 * @return Full path to the directory with temporary files.
 */
@property (readonly) NSString *pathForTemporaryFilesDirectory;

/**
 * Returns path where all avatar images will be stored.
 *
 * @return Full path to the directory with avatar images.
 */
@property (readonly) NSString *pathForAvatarsDirectory;

@end
