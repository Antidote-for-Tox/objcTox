//
//  OCTManagerConfiguration.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFileStorageProtocol.h"
#import "OCTToxOptions.h"

/**
 * Configuration for OCTManager.
 */
@interface OCTManagerConfiguration : NSObject <NSCopying>

/**
 * File storage to use.
 *
 * Default values: OCTDefaultFileStorage will be used with following parameters:
 * - tox save file is stored at "{app document directory}/me.dvor.objcTox/save.tox"
 * - downloaded files are stored at "{app document directory}/me.dvor.objcTox/downloads"
 * - uploaded files are stored at "{app document directory}/me.dvor.objcTox/uploads"
 * - avatars are stored at "{app document directory}/me.dvor.objcTox/avatars"
 * - temporary files are stored at NSTemporaryDirectory()
 */
@property (strong, nonatomic, nonnull) id<OCTFileStorageProtocol> fileStorage;

/**
 * Options for tox to use.
 *
 * Default values:
 * - IPv6 support enabled
 * - UDP support enabled
 * - No proxy is used.
 *
 * @warning On mobile devices you may want to turn off UDP support to increase battery life.
 */
@property (strong, nonatomic, nonnull) OCTToxOptions *options;

/**
 * If this parameter is set, tox save file will be copied from given path.
 * You can set this property to import tox save from some other location.
 *
 * Default value: nil.
 */
@property (strong, nonatomic, nullable) NSString *importToxSaveFromPath;

/**
 * This is default configuration for manager.
 * Each property of OCTManagerConfiguration has "Default value" field. This method returns configuration
 * with those default values set.
 *
 * @return Default configuration for OCTManager.
 */
+ (nonnull instancetype)defaultConfiguration;

@end
