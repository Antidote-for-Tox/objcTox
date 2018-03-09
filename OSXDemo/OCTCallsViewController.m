// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTCallsViewController.h"
#import "OCTSubmanagerCalls.h"
#import "OCTManager.h"
#import "OCTSubmanagerObjects.h"
#import "OCTCall.h"
#import "RLMCollectionChange+IndexSet.h"

static NSString *const kCellIdent = @"cellIdent";

@interface OCTCallsViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak, nonatomic) id<OCTManager> manager;

@property (strong, nonatomic) RLMResults<OCTCall *> *calls;
@property (strong, nonatomic) RLMNotificationToken *callsNotificationToken;

@property (weak) IBOutlet NSTableView *callsTableView;
@property (weak) IBOutlet NSView *videoContainerView;
@property (strong, nonatomic) NSView *videoView;

@end

@implementation OCTCallsViewController

- (instancetype)initWithManager:(id<OCTManager>)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    [manager.calls setupAndReturnError:nil];

    _calls = [manager.objects objectsForType:OCTFetchRequestTypeCall predicate:nil];

    return self;
}

- (void)dealloc
{
    [self.callsNotificationToken invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.callsNotificationToken = [self.calls addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        if (error) {
            NSLog(@"Failed to open Realm on background worker: %@", error);
            return;
        }

        NSTableView *tableView = weakSelf.callsTableView;

        // Initial run of the query will pass nil for the change information
        if (! changes) {
            [tableView reloadData];
            return;
        }

        [tableView beginUpdates];
        [tableView removeRowsAtIndexes:[changes deletionsSet] withAnimation:NSTableViewAnimationSlideLeft];
        [tableView insertRowsAtIndexes:[changes insertionsSet] withAnimation:NSTableViewAnimationSlideRight];
        [tableView reloadDataForRowIndexes:[changes modificationsSet] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [tableView endUpdates];
    }];
}

- (void)setupVideoView
{
    if (self.videoView == self.manager.calls.videoFeed) {
        return;
    }

    if (self.videoView) {
        [self.videoView removeFromSuperview];
        self.videoView = nil;
    }

    self.videoView = self.manager.calls.videoFeed;
    [self.videoContainerView addSubview:self.videoView];

    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.videoContainerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.videoContainerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.videoContainerView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.videoContainerView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];

    self.videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.videoView setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationVertical];
    [self.videoView setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];

    [self.videoContainerView addConstraints:@[centerX, centerY, widthConstraint, heightConstraint]];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.calls.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 300.0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self doSomeThingWithCallWithBlock:^(OCTCall *call) {
        if (call.videoIsEnabled || call.friendSendingVideo) {
            [self setupVideoView];
        }
    }];
}

#pragma mark - NSTableViewDataSource

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    OCTCall *call = self.calls[row];

    NSTextField *textField = [self.callsTableView makeViewWithIdentifier:kCellIdent owner:nil];

    if (! textField) {
        textField = [NSTextField new];
        textField.identifier = kCellIdent;
    }

    textField.stringValue = [NSString stringWithFormat:@"Friend name:%@\n"
                             @"Call\n"
                             @"Chat identifier %@\n"
                             @"call status: %ld\n"
                             @"callDuration: %f\n"
                             @"friend sending audio: %d\n"
                             @"friend receiving audio: %d\n"
                             @"friend sending video: %d\n"
                             @"friend receiving Video: %d\n",
                             call.caller.name,
                             call.chat.uniqueIdentifier, (long)call.status, call.callDuration, call.friendSendingAudio, call.friendAcceptingAudio,
                             call.friendSendingVideo, call.friendAcceptingVideo];
    ;

    return textField;
}

#pragma mark - Actions

- (IBAction)callActionButtonPressed:(NSButton *)sender
{
    [self doSomeThingWithCallWithBlock:^(OCTCall *call) {
        [self.manager.calls answerCall:call enableAudio:YES enableVideo:YES error:nil];
    }];
}

- (IBAction)sendCallControlSelected:(NSPopUpButton *)sender
{
    [self doSomeThingWithCallWithBlock:^(OCTCall *call) {
        OCTToxAVCallControl control = (OCTToxAVCallControl)[sender indexOfSelectedItem];
        [self.manager.calls sendCallControl:control toCall:call error:nil];
    }];
}

#pragma mark - Private

- (OCTCall *)callForCurrentlySelectedRow
{
    NSInteger selectedRow = self.callsTableView.selectedRow;

    if (selectedRow < 0) {
        return nil;
    }

    OCTCall *call = self.calls[selectedRow];

    return call;
}

- (BOOL)doSomeThingWithCallWithBlock:(void (^)(OCTCall *))block
{
    NSInteger selectedRow = self.callsTableView.selectedRow;

    if (selectedRow < 0) {
        return NO;
    }

    OCTCall *call = self.calls[selectedRow];

    block(call);

    return YES;
}

@end
