//
//  OCTManager.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 06.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTManagerConfiguration.h"
#import "OCTSubmanagerFriends.h"
#import "OCTSubmanagerChats.h"
#import "OCTSubmanagerAvatars.h"

@interface OCTManager : NSObject

/**
 * Submanager with all friends methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerFriends *friends;

/**
 * Submanager with all chats methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerChats *chats;

/**
 * Submanager with all user avatar methods.
 */
@property (strong, nonatomic, readonly) OCTSubmanagerAvatars *avatars;

/**
 * Create manager with configuration. There is no way to change configuration after init method. If you'd like to
 * change it you have to recreate OCTManager.
 *
 * @param configuration Configuration to be used.
 *
 * @return Initialized OCTManager.
 */
- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration;

@end
