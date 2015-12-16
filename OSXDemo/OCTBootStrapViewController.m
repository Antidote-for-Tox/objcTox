//
//  OCTBootStrapViewController.m
//  objcTox
//
//  Created by Chuong Vu on 12/9/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import "OCTBootStrapViewController.h"

static NSString *const kNibName = @"OCTBootStrap";

@interface OCTBootStrapViewController ()

@property (strong, nonatomic) OCTManagerConfiguration *configuration;
@property (weak) IBOutlet NSButton *ipv6Button;
@property (weak) IBOutlet NSButton *udpButton;

@end

@implementation OCTBootStrapViewController

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
{
    self = [super initWithNibName:kNibName bundle:nil];

    if (! self) {
        return nil;
    }

    _configuration = configuration;

    return self;
}

#pragma mark - Private

- (IBAction)bootstrapButtonTapped:(NSButton *)sender
{
    self.configuration.options.UDPEnabled = self.udpButton.state;
    self.configuration.options.IPv6Enabled = self.ipv6Button.state;

    [self.delegate didBootStrap:self];
}

@end
