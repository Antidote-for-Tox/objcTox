//
//  OCTSubmanagerFriends.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTManagerFriendsProtocol.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTToxDelegate.h"

@interface OCTSubmanagerFriends : NSObject <OCTManagerFriendsProtocol, OCTToxDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

- (void)configure;

@end
