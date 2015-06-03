//
//  OCTToxAV.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxAVConstants.h"
#import "OCTToxConstants.h"
#import "OCTToxAVDelegate.h"

@class OCTTox;

@interface OCTToxAV : NSObject

@property (weak, nonatomic) id<OCTToxAVDelegate> delegate;

#pragma mark - Class Methods

/**
 * Return toxav version in format X.Y.Z, where
 * X - The major version number.
 * Y - The minor version number.
 * Z - The patch or revision number.
 */
+ (NSString *)version;

/**
 * The major version number of toxav. Can be used to display the
 * ToxAV library version or to check whether the client is compatible with the
 * dynamically linked version of ToxAV.
 */
+ (NSUInteger)versionMajor;

/**
 * Return the minor version number of the library
 */
+ (NSUInteger)versionMinor;

/**
 * Return the patch number of the library.
 */
+ (NSUInteger)versionPatch;

/**
 * Checks if the compiled library version is compatible with
 * the passed version numbers.
 * @return YES if compatible, otherwise NO.
 */
+ (BOOL)versionIsCompatibleWith:(NSUInteger)major minor:(NSUInteger)minor patch:(NSUInteger)patch;

#pragma mark -  Lifecycle

/**
 * Creates a new Toxav object.
 * @param tox Tox object to be initialized with.
 * @param error If an error occurs, this pointer is set to an actual error object.
 */
- (instancetype)initWithTox:(OCTTox *)tox error:(NSError **)error;

#pragma mark - Call Methods

/**
 * Call a friend. This will start ringing the friend.
 * It is the client's responsibility to stop ringing after a certain timeout,
 * if such behaviour is desired. If the client does not stop ringing, the
 * library will not stop until the friend is disconnected.
 * @param friendNumber The friend number of the friend that should be called.
 * @param audioBitRate Audio bit rate in Kb/sec. Set this to kOCTToxAVAudioBitRateDisable to disable audio sending.
 * @param videoBitRate Video bit rate in Kb/sec. Set this to kOCTToxAVVideoBitRateDisable to disable video sending.
 * video sending.
 */
- (BOOL)callFriendNumber:(OCTToxFriendNumber)friendNumber audioBitRate:(OCTToxAVAudioBitRate)audioBitRate videoBitRate:(OCTToxAVVideoBitRate)videoBitRate error:(NSError **)error;

@end
