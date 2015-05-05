//
//  OCTConverterFriend.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 03.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterProtocol.h"
#import "OCTFriend.h"

@protocol OCTConverterFriendDataSource <NSObject>

- (OCTFriend *)friendWithFriendNumber:(OCTToxFriendNumber)friendNumber;

@end

/**
 * Note that OCTDBFriend has only friendNumber property, thus sortDescriptor is limited to it.
 * In case if another property will be passed converter will return nil.
 */
@interface OCTConverterFriend : NSObject <OCTConverterProtocol>

@property (weak, nonatomic) id<OCTConverterFriendDataSource> dataSource;

@end
