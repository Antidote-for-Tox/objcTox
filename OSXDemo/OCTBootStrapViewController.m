// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
    self.configuration.options.udpEnabled = self.udpButton.state;
    self.configuration.options.ipv6Enabled = self.ipv6Button.state;

    [self.delegate didBootStrap:self];
}

@end
