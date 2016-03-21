//
//  OCTFileDataInput.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTFileInputProtocol.h"

@interface OCTFileDataInput : NSObject <OCTFileInputProtocol>

- (nullable instancetype)initWithData:(nonnull NSData *)data;

- (nullable instancetype)init NS_UNAVAILABLE;
+ (nullable instancetype)new NS_UNAVAILABLE;

@end
