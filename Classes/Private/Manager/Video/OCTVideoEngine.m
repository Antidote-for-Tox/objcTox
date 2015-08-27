//
//  OCTVideoEngine.m
//  objcTox
//
//  Created by Chuong Vu on 6/19/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoEngine.h"
#import "OCTVideoView.h"
#import "OCTPixelBufferPool.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

@import AVFoundation;

static const OSType kPixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;

@interface OCTVideoEngine () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, weak) OCTVideoView *videoView;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) uint8_t *reusableUChromaPlane;
@property (nonatomic, assign) uint8_t *reusableVChromaPlane;
@property (nonatomic, assign) uint8_t *reusableYChromaPlane;
@property (strong, nonatomic) OCTPixelBufferPool *pixelPool;
@property (nonatomic, assign) NSUInteger sizeOfChromaPlanes;
@property (nonatomic, assign) NSUInteger sizeOfYPlane;

@end

@implementation OCTVideoEngine

#pragma mark - Life cycle

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
    _pixelPool = [[OCTPixelBufferPool alloc] initWithFormat:kPixelFormat];

    return self;
}

- (void)dealloc
{
    if (self.reusableUChromaPlane) {
        free(self.reusableUChromaPlane);
    }

    if (self.reusableVChromaPlane) {
        free(self.reusableVChromaPlane);
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (BOOL)setupWithError:(NSError **)error
{
    DDLogVerbose(@"%@: setupWithError", self);
    AVCaptureDevice *videoCaptureDevice = [self getDeviceForPosition:AVCaptureDevicePositionFront];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:error];

    if (! videoInput) {
        return NO;
    }

    [self.captureSession addInput:videoInput];

    self.dataOutput.alwaysDiscardsLateVideoFrames = YES;
    self.dataOutput.videoSettings = @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kPixelFormat),
    };
    [self.dataOutput setSampleBufferDelegate:self queue:self.processingQueue];

    [self.captureSession addOutput:self.dataOutput];
    AVCaptureConnection *conn = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];

    if (conn.supportsVideoOrientation) {
        [self registerOrientationNotification];
        [self orientationChanged];
    }

    return YES;
}

- (BOOL)switchToCameraFront:(BOOL)front error:(NSError **)error
{
    DDLogVerbose(@"%@: switchToCameraFront %d", self, front);

    AVCaptureDevicePosition position = front ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;

    NSArray *inputs = [self.captureSession inputs];

    AVCaptureInput *current = [inputs firstObject];
    if ([current isKindOfClass:[AVCaptureDeviceInput class]]) {
        AVCaptureDeviceInput *inputDevice = (AVCaptureDeviceInput *)current;
        if (inputDevice.device.position == position) {
            return YES;
        }
    }

    for (AVCaptureInput *input in inputs) {
        [self.captureSession removeInput:input];
    }

    AVCaptureDevice *camera = [self getDeviceForPosition:position];

    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:error];

    if (! videoInput) {
        return NO;
    }

    if (! [self.captureSession canAddInput:videoInput]) {
        // fill error?
        return NO;
    }

    [self.captureSession addInput:videoInput];

    [self orientationChanged];

    return YES;
}

- (void)startSendingVideo
{
    DDLogVerbose(@"%@: startSendingVideo", self);

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

    dispatch_async(self.processingQueue, ^{

        if (! [self isSendingVideo]) {
            return;
        }

        [self.captureSession stopRunning];
    });
}

- (BOOL)isSendingVideo
{
    DDLogVerbose(@"%@: isSendingVideo", self);
    return self.captureSession.isRunning;
}

- (void)getVideoCallPreview:(void (^)(CALayer *))completionBlock
{
    NSParameterAssert(completionBlock);
    DDLogVerbose(@"%@: videoCallPreview", self);
    dispatch_async(self.processingQueue, ^{
        AVCaptureVideoPreviewLayer *previewLayer = self.previewLayer;

        if (! self.previewLayer) {
            previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(previewLayer);
        });

        self.previewLayer = previewLayer;
    });
}

- (OCTView *)videoFeed;
{
    DDLogVerbose(@"%@: videoFeed", self);

    OCTVideoView *feed = self.videoView;

    if (! feed) {
        feed = [[OCTVideoView alloc] initWithFrame:CGRectZero];
        self.videoView = feed;
    }

    return feed;
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

    if (! self.videoView) {
        return;
    }

    size_t yBytesPerRow = MIN(width, abs(yStride));
    size_t uvBytesPerRow = MIN(width / 2, abs(uStride));

    /**
     * Create pixel buffers and copy YUV planes over
     */
    CVPixelBufferRef bufferRef = NULL;

    if (! [self.pixelPool createPixelBuffer:&bufferRef width:width height:height]) {
        return;
    }

    CVPixelBufferLockBaseAddress(bufferRef, 0);

    OCTToxAVPlaneData *ySource = yPlane;
    uint8_t *yDestinationPlane = CVPixelBufferGetBaseAddressOfPlane(bufferRef, 0);

    /* Copy yPlane data */
    for (size_t yHeight = 0; yHeight < height; yHeight++) {
        memcpy(yDestinationPlane, ySource, yBytesPerRow);
        ySource += yStride;
        yDestinationPlane += yBytesPerRow;
    }

    /* Interweave U and V */
    uint8_t *uvDestinationPlane = CVPixelBufferGetBaseAddressOfPlane(bufferRef, 1);
    OCTToxAVPlaneData *uSource = uPlane;
    OCTToxAVPlaneData *vSource = vPlane;
    for (size_t yHeight = 0; yHeight < height / 2; yHeight++) {
        for (size_t index = 0; index < uvBytesPerRow; index++) {
            uvDestinationPlane[index * 2] = uSource[index];
            uvDestinationPlane[(index * 2) + 1] = vSource[index];
        }
        uvDestinationPlane += uvBytesPerRow * 2;
        uSource += uStride;
        vSource += vStride;
    }

    CVPixelBufferUnlockBaseAddress(bufferRef, 0);

    dispatch_async(self.processingQueue, ^{

        /* Create Core Image */
#if TARGET_OS_IPHONE
        CIImage *coreImage = [CIImage imageWithCVPixelBuffer:bufferRef];

        CVPixelBufferRelease(bufferRef);

        self.videoView.image = coreImage;
#else
#warning TODO audio OSX
#endif
    });
}

#pragma mark - Buffer Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    if (! imageBuffer) {
        return;
    }

    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    size_t yHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    size_t yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    size_t yStride = MAX(CVPixelBufferGetWidthOfPlane(imageBuffer, 0), yBytesPerRow);

    size_t uvHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
    size_t uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    size_t uvStride = MAX(CVPixelBufferGetWidthOfPlane(imageBuffer, 1), uvBytesPerRow);

    size_t ySize = yBytesPerRow * yHeight;
    size_t numberOfElementsForChroma = uvBytesPerRow * uvHeight / 2;

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

        self.reusableUChromaPlane = malloc(numberOfElementsForChroma * sizeof(OCTToxAVPlaneData));
        self.reusableVChromaPlane = malloc(numberOfElementsForChroma * sizeof(OCTToxAVPlaneData));

        self.sizeOfChromaPlanes = numberOfElementsForChroma;
    }

    if (ySize > self.sizeOfYPlane) {
        if (self.reusableYChromaPlane) {
            free(self.reusableYChromaPlane);
        }
        self.reusableYChromaPlane = malloc(ySize * sizeof(OCTToxAVPlaneData));
        self.sizeOfYPlane = ySize;
    }

    /**
     * Copy the Y plane data while skipping stride
     */
    OCTToxAVPlaneData *yPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    uint8_t *yDestination = self.reusableYChromaPlane;
    for (size_t i = 0; i < yHeight; i++) {
        memcpy(yDestination, yPlane, yBytesPerRow);
        yPlane += yStride;
        yDestination += yBytesPerRow;
    }

    /**
     * Deinterleaved the UV [uvuvuvuv] planes and place them to in the reusable arrays
     */
    OCTToxAVPlaneData *uvPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    uint8_t *uDestination = self.reusableUChromaPlane;
    uint8_t *vDestination = self.reusableVChromaPlane;

    for (size_t height = 0; height < uvHeight; height++) {

        for (size_t i = 0; i < uvBytesPerRow; i += 2) {
            uDestination[i / 2] = uvPlane[i];
            vDestination[i / 2] = uvPlane[i + 1];
        }

        uvPlane += uvStride;
        uDestination += uvBytesPerRow / 2;
        vDestination += uvBytesPerRow / 2;

    }

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    uDestination = nil;
    vDestination = nil;

    NSError *error;
    if (! [self.toxav sendVideoFrametoFriend:self.friendNumber
                                       width:(OCTToxAVVideoWidth)yBytesPerRow
                                      height:(OCTToxAVVideoHeight)yHeight
                                      yPlane:self.reusableYChromaPlane
                                      uPlane:self.reusableUChromaPlane
                                      vPlane:self.reusableVChromaPlane
                                       error:&error]) {
        DDLogWarn(@"%@ error:%@ width:%zu height:%zu", self, error, yBytesPerRow, yHeight);
    }
}

#pragma mark - Private

- (AVCaptureDevice *)getDeviceForPosition:(AVCaptureDevicePosition)position
{
    DDLogVerbose(@"%@: getDeviceForPosition", self);

    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }

    return nil;
}

- (void)registerOrientationNotification
{
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
#else
#warning TODO audio OSX
#endif
}

- (void)orientationChanged
{
#if TARGET_OS_IPHONE
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    AVCaptureConnection *conn = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation orientation;

    switch (deviceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        /* Landscapes are reversed, otherwise for some reason the video will be upside down */
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            return;
    }

    conn.videoOrientation = orientation;
    self.previewLayer.connection.videoOrientation = orientation;
#else
#warning TODO audio OSX
#endif
}

@end
