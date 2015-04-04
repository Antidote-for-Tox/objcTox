//
//  OCTDefaultFileStorage.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFileStorageProtocol.h"

/**
 * Default storage for files. It has following directory structure:
 * - "base directory"
 *     - save.tox - tox save file name. You can specify it in appropriate method.
 *     - downloads - downloaded files will be stored here.
 *     - uploads - uploaded files will be stored here.
 *     - avatars - avatars will be stored here.
 * - "temporary directory" - temporary files will be stored here.
 */
@interface OCTDefaultFileStorage : NSObject <OCTFileStorageProtocol>

/**
 * Creates default file storage. Will use "save.tox" as default save file name.
 *
 * @param baseDirectory Base directory to use. It will have "downloads", "uploads", "avatars" subdirectories.
 * @param temporaryDirectory All temporary files will be stored here. You can pass NSTemporaryDirectory() here.
 */
- (instancetype)initWithBaseDirectory:(NSString *)baseDirectory temporaryDirectory:(NSString *)temporaryDirectory;

/**
 * Creates default file storage.
 *
 * @param saveFileName Name of file to store tox save data. ".tox" extension will be appended to the name.
 * @param baseDirectory Base directory to use. It will have "downloads", "uploads", "avatars" subdirectories.
 * @param temporaryDirectory All temporary files will be stored here. You can pass NSTemporaryDirectory() here.
 */
- (instancetype)initWithToxSaveFileName:(NSString *)saveFileName
                          baseDirectory:(NSString *)baseDirectory
                     temporaryDirectory:(NSString *)temporaryDirectory;

@end
