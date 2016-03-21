//
//  OCTFilePathInput.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTFileInputProtocol.h"

@interface OCTFilePathInput : NSObject <OCTFileInputProtocol>

- (nullable instancetype)initWithFilePath:(nonnull NSString *)filePath;

- (nullable instancetype)init NS_UNAVAILABLE;
+ (nullable instancetype)new NS_UNAVAILABLE;

@end
