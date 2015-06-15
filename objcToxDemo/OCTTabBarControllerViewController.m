//
//  OCTTabBarControllerViewController.m
//  objcTox
//
//  Created by Chuong Vu on 6/13/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTTabBarControllerViewController.h"

@interface OCTTabBarControllerViewController ()

@end

@implementation OCTTabBarControllerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 * #pragma mark - Navigation
 *
 * // In a storyboard-based application, you will often want to do a little preparation before navigation
 * - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 *  // Get the new view controller using [segue destinationViewController].
 *  // Pass the selected object to the new view controller.
 * }
 */


#pragma mark - OCTSubmanagerCalls Delegate

- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager receiveCall:(OCTCall *)call audioEnabled:(BOOL)audioEnabled videoEnabled:(BOOL)videoEnabled
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Receiving call" message:@"call" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:@"Reject Call"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
        NSError *error;
        BOOL status = [callSubmanager endCall:call error:&error];
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
                                     enableVideo:NO
                                           error:&error];
        if (! status) {
            NSLog(@"Accept call error: %@, %@", error.localizedDescription
                  , error.localizedFailureReason);
        }
    }];

    [alertController addAction:rejectAction];
    [alertController addAction:acceptAction];
    NSLog(@"Presented view controller");
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager audioBitRateChanged:(OCTToxAVAudioBitRate)bitRate stable:(BOOL)stable forCall:(OCTCall *)call
{}
@end
