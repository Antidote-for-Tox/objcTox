//
//  OCTFilePathOutput.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTFileOutputProtocol.h"

@interface OCTFilePathOutput : NSObject <OCTFileOutputProtocol>

@property (copy, nonatomic, readonly, nonnull) NSString *resultFilePath;

- (nullable instancetype)initWithTempFolder:(nonnull NSString *)tempFolder resultFolder:(nonnull NSString *)resultFolder;

- (nullable instancetype)init NS_UNAVAILABLE;
+ (nullable instancetype)new NS_UNAVAILABLE;

@end
