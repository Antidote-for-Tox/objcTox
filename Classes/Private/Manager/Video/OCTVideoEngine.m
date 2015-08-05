//
//  OCTVideoEngine.m
//  objcTox
//
//  Created by Chuong Vu on 6/19/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoEngine.h"
#import "OCTVideoView.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

@import AVFoundation;

static const OSType kPixelFormatCapture = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;

@interface OCTVideoEngine () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, strong) OCTVideoView *videoView;
@property (nonatomic, assign) uint8_t *reusableUChromaPlane;
@property (nonatomic, assign) uint8_t *reusableVChromaPlane;
@property (nonatomic, assign) CVPixelBufferPoolRef pixelPool;

@property (nonatomic, assign) NSUInteger sizeOfChromaPlanes;

@end

@implementation OCTVideoEngine

- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    DDLogVerbose(@"%@: init", self);

    _captureSession = [AVCaptureSession new];
    _captureSession.sessionPreset = AVCaptureSessionPresetLow;
    _dataOutput = [AVCaptureVideoDataOutput new];
    _processingQueue = dispatch_queue_create("me.dvor.objcTox.OCTVideoEngineQueue", NULL);


    NSDictionary *poolAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @0,
                                     (id)kCVPixelBufferHeightKey : @192,
                                     (id)kCVPixelBufferWidthKey : @144};

    CVPixelBufferPoolCreate(kCFAllocatorDefault,
                            NULL,
                            (__bridge CFDictionaryRef)(poolAttributes),
                            &_pixelPool);
    return self;
}

#pragma mark - Public

- (BOOL)setupWithError:(NSError **)error
{
    DDLogVerbose(@"%@: setupWithError", self);
    AVCaptureDevice *videoCaptureDevice = [self frontCamera];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:error];

    if (! videoInput) {
        return NO;
    }

    [self.captureSession addInput:videoInput];

    self.dataOutput.alwaysDiscardsLateVideoFrames = YES;
    self.dataOutput.videoSettings = @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kPixelFormatCapture),
    };
    [self.dataOutput setSampleBufferDelegate:self queue:self.processingQueue];

    [self.captureSession addOutput:self.dataOutput];
    AVCaptureConnection *conn = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
    conn.videoOrientation = AVCaptureVideoOrientationPortrait;

    return YES;
}

- (void)startSendingVideo
{
    DDLogVerbose(@"%@: startSendingVideo", self);
    self.processIncomingVideo = YES;

    dispatch_async(self.processingQueue, ^{
        if ([self isSendingVideo]) {
            return;
        }
        [self.captureSession startRunning];
    });
}

- (void)stopSendingVideo
{
    DDLogVerbose(@"%@: stopSendingVideo", self);
    self.processIncomingVideo = NO;

    dispatch_async(self.processingQueue, ^{

        if (! [self isSendingVideo]) {
            return;
        }

        [self.captureSession stopRunning];
    });
}

- (BOOL)isSendingVideo
{
    DDLogVerbose(@"%@: isVideoSessionRunning", self);
    return self.captureSession.isRunning;
}

- (CALayer *)videoCallPreview
{
    DDLogVerbose(@"%@: videoCallPreview", self);
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];

    return previewLayer;
}

- (UIView *)videoFeedWithRect:(CGRect)rect;
{
    DDLogVerbose(@"%@: videoFeedWithRect", self);
    if (! self.videoView) {
        self.videoView = [[OCTVideoView alloc] initWithFrame:rect];
    }

    return self.videoView;
}

- (void)receiveVideoFrameWithWidth:(OCTToxAVVideoWidth)width
                            height:(OCTToxAVVideoHeight)height
                            yPlane:(OCTToxAVPlaneData *)yPlane
                            uPlane:(OCTToxAVPlaneData *)uPlane
                            vPlane:(OCTToxAVPlaneData *)vPlane
                           yStride:(OCTToxAVStrideData)yStride
                           uStride:(OCTToxAVStrideData)uStride
                           vStride:(OCTToxAVStrideData)vStride
                      friendNumber:(OCTToxFriendNumber)friendNumber
{
    if (! self.processIncomingVideo || ! self.videoView) {
        return;
    }

    CVPixelBufferRef bufferRef = NULL;

    void *planeBaseAddress[3] = {(void *)yPlane, (void *)uPlane, (void *)vPlane};
    size_t planeWidths[3] = {(size_t)yStride, (size_t)uStride, (size_t)vStride};
    size_t planeHeight[3] = {height, height / 4, height / 4};
    size_t bytesPerRow[3] = {abs(yStride - width), (abs(uStride) - width) / 2, (abs(vStride) - width) / 4};

    CVReturn success = CVPixelBufferCreateWithPlanarBytes(kCFAllocatorDefault,
                                                          width, height,
                                                          kPixelFormatCapture,
                                                          NULL,
                                                          0,
                                                          2,
                                                          planeBaseAddress,
                                                          planeWidths, planeHeight, bytesPerRow,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          &bufferRef);

    if (success != kCVReturnSuccess) {
        DDLogWarn(@"Error:%d CVPixelBufferCreateWithPlanarBytes",  success);
    }

    CIImage *coreImage = [CIImage imageWithCVPixelBuffer:bufferRef];
    CVPixelBufferRelease(bufferRef);

    self.videoView.image = coreImage;
}

#pragma mark - Buffer Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    if (! imageBuffer) {
        return;
    }

    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    OCTToxAVVideoWidth width = (OCTToxAVVideoWidth)CVPixelBufferGetWidth(imageBuffer);
    OCTToxAVVideoHeight height = (OCTToxAVVideoHeight)CVPixelBufferGetHeight(imageBuffer);
    NSUInteger numberOfElementsForChroma = height * width / 2;

    uint8_t *yPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    uint8_t *uvPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);

    /**
     * Recreate the buffers if the original ones are too small
     */
    if (numberOfElementsForChroma > self.sizeOfChromaPlanes) {

        if (self.reusableUChromaPlane) {
            free(self.reusableUChromaPlane);
        }

        if (self.reusableVChromaPlane) {
            free(self.reusableVChromaPlane);
        }

        self.reusableUChromaPlane = malloc(numberOfElementsForChroma * sizeof(uint8_t));
        self.reusableVChromaPlane = malloc(numberOfElementsForChroma * sizeof(uint8_t));

        self.sizeOfChromaPlanes = numberOfElementsForChroma;
    }

    /**
     * Deinterleaved the UV planes and place them to in the reusable arrays
     */
    for (int i = 0; i < (height * width / 2); i += 2) {
        self.reusableUChromaPlane[i / 2] = uvPlane[i];
        self.reusableVChromaPlane[i / 2] = uvPlane[i+1];
    }

    NSError *error;
    if (! [self.toxav sendVideoFrametoFriend:self.friendNumber
                                       width:width
                                      height:height
                                      yPlane:yPlane
                                      uPlane:self.reusableUChromaPlane
                                      vPlane:self.reusableVChromaPlane
                                       error:&error]) {
        DDLogWarn(@"%@ error:%@ width:%d height:%d", self, error, width, height);
    }

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

#pragma mark - Private

- (AVCaptureDevice *)frontCamera
{
    DDLogVerbose(@"%@: frontCamera", self);
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

@end
