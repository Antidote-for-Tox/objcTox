//
//  OCTToxAVConstants.h
//  objcTox
//
//  Created by Chuong Vu on 6/2/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTToxAVConstants.h"

typedef uint32_t OCTToxAVAudioBitRate;
typedef const int16_t OCTToxAVPCMData;
typedef size_t OCTToxAVSampleCount;
typedef uint8_t OCTToxAVChannels;
typedef uint32_t OCTToxAVSampleRate;

typedef uint32_t OCTToxAVVideoBitRate;
typedef uint16_t OCTToxAVVideoWidth;
typedef uint16_t OCTToxAVVideoHeight;
typedef const uint8_t OCTToxAVPlaneData;
typedef const int32_t OCTToxAVStrideData;

extern const OCTToxAVAudioBitRate kOCTToxAVAudioBitRateDisable;
extern const OCTToxAVVideoBitRate kOCTToxAVVideoBitRateDisable;
extern NSString *const kOCTToxAVErrorDomain;

/*******************************************************************************
 *
 * Error Codes
 *
 ******************************************************************************/

/**
 * Error codes for init method.
 */
typedef NS_ENUM(NSUInteger, OCTToxAVErrorInitCode) {
    OCTToxAVErrorInitCodeUnknown,
    /**
     * One of the arguments to the function was NULL when it was not expected.
     */
    OCTToxAVErrorInitNULL,

    /**
     * Memory allocation failure while trying to allocate structures required for
     * the A/V session.
     */
    OCTToxAVErrorInitCodeMemoryError,

    /**
     * Attempted to create a second session for the same Tox instance.
     */
    OCTToxAVErrorInitMultiple,
};

/**
 * Error codes for call setup.
 */
typedef NS_ENUM(NSUInteger, OCTToxAVErrorCall) {
    OCTToxAVErrorCallUnknown,

    /**
     * A resource allocation error occurred while trying to create the structures
     * required for the call.
     */
    OCTToxAVErrorCallMalloc,

    /**
     * The friend number did not designate a valid friend.
     */
    OCTToxAVErrorCallFriendNotFound,

    /**
     * The friend was valid, but not currently connected.
     */
    OCTToxAVErrorCallFriendNotConnected,

    /**
     * Attempted to call a friend while already in an audio or video call with
     * them.
     */
    OCTToxAVErrorCallAlreadyInCall,

    /**
     * Audio or video bit rate is invalid.
     */
    OCTToxAVErrorCallInvalidBitRate,
};
