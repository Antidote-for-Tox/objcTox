//
//  OCTAudioEngine.h
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCTAudioEngine : NSObject

/**
 * Starts the Audio Processing Graph.
 * @param error Pointer to error object.
 * @return YES on success, otherwise NO.
 */
-(BOOL)startAudioFlow:(NSError **)error;

/**
 * Stops the Audio Processing Graph.
 * @param error Pointer to error object.
 * @return YES on success, otherwise NO.
 */
-(BOOL)stopAudioFlow:(NSError **)error;

/**
 * Enable or disable the microphone input.
 * @param enable YES to turn on microphone input, NO otherwise.
 * @return YES if successful, NO otherwise.
 */
-(BOOL)microphoneInput:(BOOL)enable;

/**
 * Mute the output
 * @param disable YES to disable, NO otherwise
 * @param error Pointer to error object
 * @return YES on success, no Otherwise.
 */
-(BOOL)outputEnable:(BOOL)enable error:(NSError **)error;

/**
 * Checks if the Audio Graph is processing.
 * @return YES if Audio Graph is running, otherwise No.
 */
-(BOOL)isAudioRunning;


@end
