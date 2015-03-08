//
//  OCTManagerAvatarsProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OCTManagerAvatarsProtocol <NSObject>

/**
 * Sets avatar for current user.
 *
 * @param avatar Image containing avatar, or nil if you want to remove it.
 */
- (void)setAvatar:(UIImage *)avatar;

/**
 * Returns avatar for current user. If you want just to check if user avatar exist, it would be better to use
 * `has avatar` method as it is faster.
 *
 * @return User avatar or nil if avatar isn't set.
 */
- (UIImage *)avatar;

/**
 * Indicates if user has avatar.
 *
 * @return YES is avatar exists, NO otherwise.
 */
- (BOOL)hasAvatar;

@end
