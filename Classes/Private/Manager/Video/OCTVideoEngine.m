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

static uint8_t *reusableUChromaPlane;
static uint8_t *reusableVChromaPlane;

static const OSType kPixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;

@interface OCTVideoEngine () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, strong) OCTVideoView *videoView;

@property (nonatomic, assign) NSUInteger sizeOfChromaPlanes;

@end

@implementation OCTVideoEngine

- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    _captureSession = [AVCaptureSession new];
    _dataOutput = [AVCaptureVideoDataOutput new];
    _processingQueue = dispatch_queue_create("me.dvor.objcTox.OCTVideoEngineQueue", NULL);

    return self;
}

#pragma mark - Public

- (BOOL)setupWithError:(NSError **)error
{
    AVCaptureDevice *videoCaptureDevice = [self frontCamera];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:error];

    if (! videoInput) {
        return NO;
    }

    [self.captureSession addInput:videoInput];

    [self.dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSNumber *value  = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    [self.dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:value
                                                                  forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.dataOutput setSampleBufferDelegate:self queue:self.processingQueue];

    [self.captureSession addOutput:self.dataOutput];

    return YES;
}

- (void)startSendingVideo
{
    self.processIncomingVideo = YES;
    if ([self isVideoSessionRunning]) {
        return;
    }

    dispatch_async(self.processingQueue, ^{
        [self.captureSession startRunning];
    });
}

- (void)stopSendingVideo
{
    self.processIncomingVideo = NO;

    if (! [self isVideoSessionRunning]) {
        return;
    }

    dispatch_async(self.processingQueue, ^{
        [self.captureSession stopRunning];
    });
}

- (BOOL)isVideoSessionRunning
{
    return self.captureSession.isRunning;
}

- (CALayer *)videoCallPreview
{
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];

    return previewLayer;
}

- (UIView *)videoFeedWithRect:(CGRect)rect;
{
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
    // Create CVPixelBuffer -->CIImage --> OCTVideoView?
    CVPixelBufferRef bufferRef = NULL;

    void *planeBaseAddress[3] = {yPlane, uPlane, vPlane};
    size_t planeWidths[3] = {(size_t)yStride, (size_t)uStride, (size_t)vStride};
    size_t planeHeight[3] = {height, height / 4, height / 4};
    size_t bytesPerRow[3] = {abs(yStride - width), (abs(uStride) - width) / 2, (abs(vStride) - width) / 4};

    CVReturn success = CVPixelBufferCreateWithPlanarBytes(kCFAllocatorDefault,
                                                          width, height,
                                                          kPixelFormat,
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

    OCTToxAVVideoWidth width = CVPixelBufferGetWidth(imageBuffer);
    OCTToxAVVideoHeight height = CVPixelBufferGetHeight(imageBuffer);

    uint8_t *yPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    uint8_t *uvPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);

    NSUInteger numberOfElementsForChroma = height * width / 4;

    if (numberOfElementsForChroma > self.sizeOfChromaPlanes) {

        if (reusableUChromaPlane) {
            free(reusableUChromaPlane);
        }

        if (reusableVChromaPlane) {
            free(reusableVChromaPlane);
        }

        reusableUChromaPlane = malloc(numberOfElementsForChroma * sizeof(uint8_t));
        reusableVChromaPlane = malloc(numberOfElementsForChroma * sizeof(uint8_t));

        self.sizeOfChromaPlanes = numberOfElementsForChroma;
    }

    for (int i = 0; i < (height * width / 4); i += 2) {
        reusableUChromaPlane[i / 2] = uvPlane[i];
        reusableVChromaPlane[i / 2] = uvPlane[i+1];
    }

    [self.toxav sendVideoFrametoFriend:self.friendNumber
                                 width:width
                                height:height
                                yPlane:yPlane
                                uPlane:reusableUChromaPlane
                                vPlane:reusableVChromaPlane
                                 error:nil];

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

#pragma mark - Private

- (AVCaptureDevice *)frontCamera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

@end
