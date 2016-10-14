// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "OCTVideoEngine.h"
#import "OCTPixelBufferPool.h"
#import "OCTVideoView.h"
#import "OCTToxAV.h"

#include "test_straight3p.h"
#include "test_stride13p.h"
#include "test_backwards_3p.h"
#include "test_backwards_stride13p.h"
#include "test_good.h"

@import AVFoundation;

@interface OCTVideoEngine (Testing)

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, weak) OCTVideoView *videoView;
@property (strong, nonatomic) OCTPixelBufferPool *pixelPool;

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end

@interface OCTVideoEngineTests : XCTestCase

@property (strong, nonatomic) OCTVideoEngine *videoEngine;
@property (strong, nonatomic) id mockedToxAV;
@property (strong, nonatomic) id mockedCaptureSession;

@end

@implementation OCTVideoEngineTests

- (void)setUp
{
    [super setUp];
    self.videoEngine = [OCTVideoEngine new];
    self.mockedToxAV = OCMClassMock([OCTToxAV class]);
    self.videoEngine.toxav = self.mockedToxAV;
    self.mockedCaptureSession = OCMClassMock([AVCaptureSession class]);
    self.videoEngine.captureSession = self.mockedCaptureSession;

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self.mockedToxAV stopMocking];
    self.mockedToxAV = nil;
    [self.mockedCaptureSession stopMocking];
    self.mockedCaptureSession = nil;
    self.videoEngine = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.videoEngine);
}

- (void)testStartSendingVideo
{
    OCMStub([self.mockedCaptureSession isRunning]).andReturn(NO);

    [self.videoEngine startSendingVideo];

    dispatch_sync(self.videoEngine.processingQueue, ^{
        OCMVerify([self.mockedCaptureSession startRunning]);
    });
}

- (void)testStopSendingVideo
{
    OCMStub([self.mockedCaptureSession isRunning]).andReturn(YES);

    [self.videoEngine stopSendingVideo];

    dispatch_sync(self.videoEngine.processingQueue, ^{
        OCMVerify([self.mockedCaptureSession stopRunning]);
    });
}

- (void)testIsSendingVideo
{
    OCMStub([self.mockedCaptureSession isRunning]).andReturn(YES);

    XCTAssertTrue([self.videoEngine isSendingVideo]);
}

- (void)testGetVideoCallPreview
{
    id mockedCapturePreviewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
    OCMStub([mockedCapturePreviewLayer layerWithSession:self.mockedCaptureSession]).andReturn(mockedCapturePreviewLayer);

    dispatch_sync(self.videoEngine.processingQueue, ^{
        [self.videoEngine getVideoCallPreview:^(CALayer *layer) {
            XCTAssertEqualObjects(layer, mockedCapturePreviewLayer);
        }];
    });
}

- (void)testVideoFeed
{
    id mockedVideoView = OCMClassMock([OCTVideoView class]);
    OCMStub([mockedVideoView view]).andReturn(mockedVideoView);

    OCTView *view = [self.videoEngine videoFeed];

    XCTAssertEqualObjects(view, mockedVideoView);
}

- (void)testReceiveVideoFrame
{
    OCTToxAVVideoWidth width = 10;
    OCTToxAVVideoHeight height = 10;

    id mockedPixelPool = OCMClassMock([OCTPixelBufferPool class]);
    self.videoEngine.pixelPool = mockedPixelPool;

    OCMStub([mockedPixelPool createPixelBuffer:[OCMArg anyPointer] width:10 height:10]).andReturn(NO);

    self.videoEngine.videoView = OCMClassMock([OCTVideoView class]);

    [self.videoEngine receiveVideoFrameWithWidth:width
                                          height:height
                                          yPlane:nil
                                          uPlane:nil
                                          vPlane:nil
                                         yStride:10
                                         uStride:10
                                         vStride:10
                                    friendNumber:10];

    dispatch_sync(self.videoEngine.processingQueue, ^{
        OCMVerify([mockedPixelPool createPixelBuffer:[OCMArg anyPointer]
                                               width:width
                                              height:height]);
    });
}

- (void)performYUVCheckWithPlanes:(uint8_t * [3])planes strides:(OCTToxAVStrideData[3])strides
{
    OCTToxAVVideoWidth width = 30;
    OCTToxAVVideoHeight height = 30;
    self.videoEngine.videoView = OCMClassMock([OCTVideoView class]);
    id ciMock = OCMClassMock([CIImage class]);

    OCMStub([ciMock imageWithCVPixelBuffer:[OCMArg anyPointer]]).andDo(^(NSInvocation *invocation) {
        CVPixelBufferRef pb = NULL;
        [invocation getArgument:&pb atIndex:2];

        XCTAssertNotNil((__bridge id)pb);
        XCTAssertEqual(CVPixelBufferGetPixelFormatType(pb), kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);

        // now we compare the buffer contents with the known good result
        CVPixelBufferLockBaseAddress(pb, kCVPixelBufferLock_ReadOnly);
        uint8_t *y = CVPixelBufferGetBaseAddressOfPlane(pb, 0);
        uint8_t *uv = CVPixelBufferGetBaseAddressOfPlane(pb, 1);

        uint8_t *testyrow = y;
        uint8_t *goodyrow = test_good_y;
        for (int i = 0; i < 30; ++i) {
            XCTAssertEqual(memcmp(testyrow, goodyrow, 30), 0);
            testyrow += CVPixelBufferGetBytesPerRowOfPlane(pb, 0);
            goodyrow += 30;
        }

        uint8_t *testuvrow = uv;
        uint8_t *gooduvrow = test_good_uv;
        for (int i = 0; i < 15; ++i) {
            XCTAssertEqual(memcmp(testuvrow, gooduvrow, 30), 0);
            testuvrow += CVPixelBufferGetBytesPerRowOfPlane(pb, 1);
            gooduvrow += 30;
        }

        void *ret = nil;
        [invocation setReturnValue:&ret];
    });

    [self.videoEngine receiveVideoFrameWithWidth:width
                                          height:height
                                          yPlane:planes[0]
                                          uPlane:planes[1]
                                          vPlane:planes[2]
                                         yStride:strides[0]
                                         uStride:strides[1]
                                         vStride:strides[2]
                                    friendNumber:10];

    dispatch_sync(self.videoEngine.processingQueue, ^{
        OCMVerify([ciMock imageWithCVPixelBuffer:[OCMArg anyPointer]]);
    });
}

- (void)testReceivePackedVideoFrame
{
    uint8_t *planes[3] = {test_str83p_y, test_str83p_u, test_str83p_v};
    OCTToxAVStrideData strides[3] = {30, 15, 15};

    [self performYUVCheckWithPlanes:planes strides:strides];
}

- (void)testReceiveStridedVideoFrame
{
    uint8_t *planes[3] = {test_stride13p_y, test_stride13p_u, test_stride13p_v};
    OCTToxAVStrideData strides[3] = {31, 16, 16};

    [self performYUVCheckWithPlanes:planes strides:strides];
}

- (void)testReceiveUpsideDownStridedVideoFrame
{
    uint8_t *planes[3] = {test_backwards_stride13p_y, test_backwards_stride13p_u, test_backwards_stride13p_v};
    OCTToxAVStrideData strides[3] = {-31, -16, -16};

    [self performYUVCheckWithPlanes:planes strides:strides];
}

- (void)testReceiveUpsideDownVideoFrame
{
    uint8_t *planes[3] = {test_backwards_3p_y, test_backwards_3p_u, test_backwards_3p_v};
    OCTToxAVStrideData strides[3] = {-30, -15, -15};

    [self performYUVCheckWithPlanes:planes strides:strides];
}

@end
