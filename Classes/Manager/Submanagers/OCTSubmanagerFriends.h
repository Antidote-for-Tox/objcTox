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

@interface OCTSubmanagerFriends : NSObject <OCTManagerFriendsProtocol>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@end
