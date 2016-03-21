//
//  OCTFileDataOutput.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTFileOutputProtocol.h"

@interface OCTFileDataOutput : NSObject <OCTFileOutputProtocol>

/**
 * Result data. This property will contain data only after download finishes.
 */
@property (strong, nonatomic, readonly, nullable) NSData *resultData;

@end
