//
//  OCTFileTools.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 17.04.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCTFileTools : NSObject

/**
 * Creates filePath in directory for given fileName. In case if file already exists appends " N" suffix,
 * e.g. "file 2.txt", "file 3.txt".
 *
 * @param directory Directory part of filePath.
 * @param fileName Name of the file to use in path.
 *
 * @return File path to file that does not exist.
 */
+ (nonnull NSString *)createNewFilePathInDirectory:(nonnull NSString *)directory fileName:(nonnull NSString *)fileName;

@end
