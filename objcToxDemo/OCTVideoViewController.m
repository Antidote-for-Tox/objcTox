//
//  OCTVideoViewController.m
//  objcTox
//
//  Created by Chuong Vu on 8/1/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoViewController.h"
#import "OCTSubmanagerCalls.h"

static const CGFloat kEdgeInsets = 25.0;

@interface OCTVideoViewController ()

@property (nonatomic, strong) OCTSubmanagerCalls *manager;
@property (nonatomic, strong) UIButton *dismissVCButton;
@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, weak) CALayer *previewLayer;
@property (nonatomic, strong) UIView *videoFeed;
@end

@implementation OCTVideoViewController

- (instancetype)initWithCallManager:(OCTSubmanagerCalls *)manager
{
    self = [super self];

    if (! self) {
        return nil;
    }

    _manager = manager;

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createDismissVCButton];
    [self createPreviewView];
    [self createVideoFeedView];

    [self createPreviewViewConstraints];
}

- (void)viewDidLayoutSubviews
{
    [self adjustPreviewLayer];
}

- (void)createVideoViewConstraints
{
    NSLayoutConstraint *videoViewTop = [NSLayoutConstraint constraintWithItem:self.videoFeed
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:kEdgeInsets];

    NSLayoutConstraint *videoViewRight = [NSLayoutConstraint constraintWithItem:self.videoFeed
                                                                      attribute:NSLayoutAttributeRight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeRight
                                                                     multiplier:1.0
                                                                       constant:-kEdgeInsets];

    NSLayoutConstraint *videoViewLeft = [NSLayoutConstraint constraintWithItem:self.videoFeed
                                                                     attribute:NSLayoutAttributeLeft
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeft
                                                                    multiplier:1.0
                                                                      constant:kEdgeInsets];

    NSLayoutConstraint *videoViewBottom = [NSLayoutConstraint constraintWithItem:self.videoFeed
                                                                       attribute:NSLayoutAttributeBottom
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.previewView
                                                                       attribute:NSLayoutAttributeTop
                                                                      multiplier:1.0
                                                                        constant:0];

    [self.view addConstraints:@[videoViewBottom, videoViewLeft, videoViewRight, videoViewTop]];
}

- (void)createPreviewViewConstraints
{
    NSLayoutConstraint *previewViewBottom = [NSLayoutConstraint constraintWithItem:self.previewView
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0
                                                                          constant:-kEdgeInsets];

    NSLayoutConstraint *previewViewLeft = [NSLayoutConstraint constraintWithItem:self.previewView
                                                                       attribute:NSLayoutAttributeLeft
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeLeft
                                                                      multiplier:1.0
                                                                        constant:kEdgeInsets];

    NSLayoutConstraint *previewViewRight = [NSLayoutConstraint constraintWithItem:self.previewView
                                                                        attribute:NSLayoutAttributeRight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.view
                                                                        attribute:NSLayoutAttributeRight
                                                                       multiplier:1.0
                                                                         constant:-kEdgeInsets];

    NSLayoutConstraint *previewViewHeight = [NSLayoutConstraint constraintWithItem:self.previewView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:0.5
                                                                          constant:-kEdgeInsets];

    [self.view addConstraints:@[previewViewBottom, previewViewHeight, previewViewLeft, previewViewRight]];
}

- (void)createPreviewView
{
    self.previewView = [UIView new];
    self.previewView.backgroundColor = [UIColor blackColor];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.previewView];
}

- (void)adjustPreviewLayer
{
    if (! self.previewLayer) {
        __weak OCTVideoViewController *weakSelf = self;

        [self.previewView.layer addSublayer:self.previewLayer];
        [self.manager getVideoCallPreview:^(CALayer *layer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                OCTVideoViewController *strongSelf = weakSelf;
                [strongSelf.previewView.layer addSublayer:layer];
                strongSelf.previewLayer = layer;
                strongSelf.previewLayer.frame = strongSelf.previewView.bounds;
            });
        }];
    }
    else {
        self.previewLayer.frame = self.previewView.bounds;
    }
}

- (void)createVideoFeedView
{
    self.videoFeed = [self.manager videoFeed];
    self.videoFeed.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.videoFeed];
    [self createVideoViewConstraints];
}

- (void)createDismissVCButton
{
    self.dismissVCButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    self.dismissVCButton.backgroundColor = [UIColor clearColor];
    [self.dismissVCButton addTarget:self
                             action:@selector(dismissViewButtonPressed)
                   forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.dismissVCButton];
}

- (void)dismissViewButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
