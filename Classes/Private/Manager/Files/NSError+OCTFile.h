//
//  NSError+OCTFile.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTToxConstants.h"

@class OCTMessageAbstract;

@interface NSError (OCTFile)

+ (NSError *)sendFileErrorInternalError;
+ (NSError *)sendFileErrorCannotReadFile;
+ (NSError *)sendFileErrorCannotSaveFileToUploads;
+ (NSError *)sendFileErrorFriendNotFound;
+ (NSError *)sendFileErrorFriendNotConnected;
+ (NSError *)sendFileErrorNameTooLong;
+ (NSError *)sendFileErrorTooMany;
+ (NSError *)sendFileErrorFromToxFileSendError:(OCTToxErrorFileSend)code;

+ (NSError *)acceptFileErrorInternalError;
+ (NSError *)acceptFileErrorCannotWriteToFile;
+ (NSError *)acceptFileErrorFriendNotFound;
+ (NSError *)acceptFileErrorFriendNotConnected;
+ (NSError *)acceptFileErrorWrongMessage:(OCTMessageAbstract *)message;
+ (NSError *)acceptFileErrorFromToxFileSendChunkError:(OCTToxErrorFileSendChunk)code;
+ (NSError *)acceptFileErrorFromToxFileControl:(OCTToxErrorFileControl)code;

+ (NSError *)fileTransferErrorWrongMessage:(OCTMessageAbstract *)message;

@end
