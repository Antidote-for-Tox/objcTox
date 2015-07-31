//
//  OCTVideoViewController.m
//  objcTox
//
//  Created by Chuong Vu on 7/30/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoViewController.h"
#import "OCTVideoView.h"

@interface OCTVideoViewController ()

@end

@implementation OCTVideoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect rect = self.view.bounds;

    OCTVideoView *videoView = [[OCTVideoView alloc] initWithFrame:rect];

    self.view = videoView;
}


@end
