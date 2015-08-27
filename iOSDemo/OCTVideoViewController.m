//
//  OCTVideoViewController.m
//  objcTox
//
//  Created by Chuong Vu on 8/1/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoViewController.h"
#import "OCTSubmanagerCalls.h"
#import "OCTTableViewController.h"

static const CGFloat kEdgeInsets = 25.0;

@interface OCTVideoViewController ()

@property (nonatomic, strong) OCTSubmanagerCalls *manager;
@property (nonatomic, strong) UIButton *menuActionButton;
@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, weak) CALayer *previewLayer;
@property (nonatomic, strong) UIView *videoFeed;
@property (nonatomic, strong) OCTCall *call;
@end

@implementation OCTVideoViewController

- (instancetype)initWithCallManager:(OCTSubmanagerCalls *)manager call:(OCTCall *)call
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;
    _call = call;

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
    self.previewView.userInteractionEnabled = NO;
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
            OCTVideoViewController *strongSelf = weakSelf;
            [strongSelf.previewView.layer addSublayer:layer];
            strongSelf.previewLayer = layer;
            strongSelf.previewLayer.frame = strongSelf.previewView.bounds;
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
    self.videoFeed.userInteractionEnabled = NO;
    [self.view addSubview:self.videoFeed];
    [self createVideoViewConstraints];
}

- (void)createDismissVCButton
{
    self.menuActionButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    self.menuActionButton.backgroundColor = [UIColor clearColor];
    [self.menuActionButton addTarget:self
                              action:@selector(showActionDialog)
                    forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.menuActionButton];
}

- (void)showActionDialog
{
    __weak OCTVideoViewController *weakSelf = self;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Video"
                                                                             message:@"actions"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *stopSendingVideoAction = [UIAlertAction actionWithTitle:@"Stop sending video"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action) {
        [weakSelf stopSendingVideo];
    }];

    UIAlertAction *startSendingVideoAction = [UIAlertAction actionWithTitle:@"Start sending video"
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction *action) {
        [weakSelf startSendingVideo];
    }];

    UIAlertAction *switchToRearAction = [UIAlertAction actionWithTitle:@"Use rear camera"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
        [weakSelf switchToBack];
    }];

    UIAlertAction *switchToFrontAction = [UIAlertAction actionWithTitle:@"Use front camera"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
        [weakSelf switchToFront];
    }];

    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss view"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction *action) {
        [weakSelf dismissViewButtonPressed];
    }];

    [alertController addAction:stopSendingVideoAction];
    [alertController addAction:startSendingVideoAction];
    [alertController addAction:switchToRearAction];
    [alertController addAction:switchToFrontAction];
    [alertController addAction:dismissAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Touch actions

- (void)dismissViewButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stopSendingVideo
{
    [self.manager enableVideoSending:NO forCall:self.call error:nil];
}

- (void)startSendingVideo
{
    [self.manager enableVideoSending:YES forCall:self.call error:nil];
}

- (void)switchToFront
{
    [self.manager switchToCameraFront:YES error:nil];
}

- (void)switchToBack
{
    [self.manager switchToCameraFront:NO error:nil];
}
@end
