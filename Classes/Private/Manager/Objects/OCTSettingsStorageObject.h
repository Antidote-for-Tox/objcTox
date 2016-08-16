//
//  OCTSettingsStorageObject.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 03/09/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"

@interface OCTSettingsStorageObject : OCTObject

@property BOOL bootstrapDidConnect;

/**
 * UIImage with avatar of user.
 */
@property NSData *userAvatarData;

/**
 * Generic data to be used by user of the library.
 * It shouldn't be used by objcTox itself.
 */
@property NSData *genericSettingsData;

@end
