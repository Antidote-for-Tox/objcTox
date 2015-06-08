//
//  OCTAudioEngine+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/7/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTAudioEngine.h"
@import AVFoundation;

/**
 * OCTAudioEngine functions
 */
extern OSStatus (*_NewAUGraph)(AUGraph *outGraph);
extern OSStatus (*_AUGraphAddNode)(
    AUGraph inGraph,
    const AudioComponentDescription *inDescription,
    AUNode *outNode);
extern OSStatus (*_AUGraphOpen)(AUGraph inGraph);
extern OSStatus (*_AUGraphNodeInfo)(AUGraph inGraph,
                                    AUNode inNode,
                                    AudioComponentDescription *outDescription,
                                    AudioUnit *outAudioUnit);
extern OSStatus (*_AUGraphStart)(AUGraph inGraph);
extern OSStatus (*_AUGraphStop)(AUGraph inGraph);
extern OSStatus (*_AUGraphInitialize)(AUGraph inGraph);
extern OSStatus (*_AUGraphUninitialize)(AUGraph inGraph);
extern OSStatus (*_AUGraphIsRunning)(AUGraph inGraph, Boolean *outIsRunning);

extern OSStatus (*_AudioUnitSetProperty)(AudioUnit inUnit,
                                         AudioUnitPropertyID inID,
                                         AudioUnitScope inScope,
                                         AudioUnitElement inElement,
                                         const void *inData,
                                         UInt32 inDataSize
);
extern OSStatus (*_AudioUnitRender)(AudioUnit inUnit,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inOutputBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData
);

extern OSStatus (*_DisposeAUGraph)(AUGraph inGraph);

@interface OCTAudioEngine (Private)

@property (nonatomic, assign) AUGraph processingGraph;
@property (nonatomic, assign) AudioUnit ioUnit;

- (void)fillError:(NSError **)error
         withCode:(NSUInteger)code
      description:(NSString *)description
    failureReason:(NSString *)failureReason;

@end
