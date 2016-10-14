// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTTabBarControllerViewController.h"

@interface OCTTabBarControllerViewController ()

@end

@implementation OCTTabBarControllerViewController

#pragma mark - OCTSubmanagerCalls Delegate

- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager receiveCall:(OCTCall *)call audioEnabled:(BOOL)audioEnabled videoEnabled:(BOOL)videoEnabled
{
    NSString *title = [NSString stringWithFormat:@"audio: %d video: %d", audioEnabled, videoEnabled];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Receiving call" message:title preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:@"Reject Call"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
        NSError *error;
        BOOL status = [callSubmanager sendCallControl:OCTToxAVCallControlCancel toCall:call error:&error];
        if (! status) {
            NSLog(@"End call error: %@, %@", error.localizedDescription
                  , error.localizedFailureReason);
        }
    }];

    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"Accept"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
        NSError *error;
        BOOL status = [callSubmanager answerCall:call
                                     enableAudio:YES
                                     enableVideo:YES
                                           error:&error];
        if (! status) {
            NSLog(@"Accept call error: %@, %@", error.localizedDescription
                  , error.localizedFailureReason);
        }
    }];

    [alertController addAction:rejectAction];
    [alertController addAction:acceptAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager audioBitRateChanged:(OCTToxAVAudioBitRate)bitRate stable:(BOOL)stable forCall:(OCTCall *)call
{}
@end
