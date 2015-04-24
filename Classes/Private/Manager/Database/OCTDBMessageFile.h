//
//  OCTDBMessageFile.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBMessageAbstract.h"
#import "OCTMessageFile.h"

@interface OCTDBMessageFile : OCTDBMessageAbstract

@property int fileType;
@property long long fileSize;
@property NSString *fileName;
@property NSString *filePath;
@property NSString *fileUTI;

- (instancetype)initWithMessageFile:(OCTMessageFile *)message;

/**
 * Please note that OCTFriend isn't stored in database.
 * OCTMessageAbstract object will have sender with filled friendNumber and empty other fields.
 */
- (OCTMessageFile *)message;

@end
