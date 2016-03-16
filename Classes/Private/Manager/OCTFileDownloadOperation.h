//
//  OCTFileDownloadOperation.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"

@class OCTTox;

@interface OCTFileDownloadOperation : OCTFileBaseOperation

/**
 * Call this method to get next chunk to operation.
 *
 * @param chunk Next chunk of data to append to file.
 * @param position Position in file to append chunk.
 */
- (void)receiveChunk:(NSData *)chunk position:(OCTToxFileSize)position;

@end
