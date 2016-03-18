//
//  OCTSubmanagerFilesProgressSubscriber.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCTMessageAbstract;

@protocol OCTSubmanagerFilesProgressSubscriber <NSObject>

/**
 * Method called on download/upload progress.
 *
 * @param progress Progress of download/upload. From 0.0 to 1.0.
 * @param message File message with progress update.
 * @param bytesPerSecond Speed of download/upload.
 * @param eta Estimated time of finish of download/upload.
 */
- (void)submanagerFilesOnProgressUpdate:(CGFloat)progress
                                message:(nonnull OCTMessageAbstract *)message
                         bytesPerSecond:(OCTToxFileSize)bytesPerSecond
                                    eta:(CFTimeInterval)eta;

@end
