//
//  OCTCallsViewController.m
//  objcTox
//
//  Created by Chuong Vu on 12/25/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import "OCTCallsViewController.h"
#import "OCTSubmanagerCalls.h"
#import "OCTManager.h"
#import "OCTSubmanagerObjects.h"
#import "RBQFetchedResultsController.h"
#import "OCTCall.h"

static NSString *const kCellIdent = @"cellIdent";

@interface OCTCallsViewController () <RBQFetchedResultsControllerDelegate,
                                      NSTableViewDataSource,
                                      NSTableViewDelegate>

@property (strong, nonatomic) OCTManager *manager;
@property (strong, nonatomic) RBQFetchedResultsController *callsController;
@property (weak) IBOutlet NSTableView *callsTableView;
@property (weak) IBOutlet NSView *videoContainerView;
@property (strong, nonatomic) NSView *videoView;

@end

@implementation OCTCallsViewController

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    [manager.calls setupWithError:nil];

    RBQFetchRequest *fetchRequest = [manager.objects
                                     fetchRequestForType:OCTFetchRequestTypeCall
                                           withPredicate:nil];

    _callsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    _callsController.delegate = self;
    [_callsController performFetch];

    return self;
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

#pragma mark - RBQFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    [self.callsTableView beginUpdates];
}

- (void)controller:(RBQFetchedResultsController *)controller didChangeObject:(RBQSafeRealmObject *)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(RBQFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSIndexSet *newSet = [[NSIndexSet alloc] initWithIndex:newIndexPath.row];
    NSIndexSet *oldSet = [[NSIndexSet alloc] initWithIndex:indexPath.row];
    NSIndexSet *columnSet = [[NSIndexSet alloc] initWithIndex:0];


    switch (type) {
        case RBQFetchedResultsChangeInsert:
            [self.callsTableView insertRowsAtIndexes:newSet withAnimation:NSTableViewAnimationSlideRight];
            break;
        case RBQFetchedResultsChangeDelete:
            [self.callsTableView removeRowsAtIndexes:oldSet withAnimation:NSTableViewAnimationSlideLeft];
            break;
        case RBQFetchedResultsChangeUpdate:
            [self.callsTableView reloadDataForRowIndexes:oldSet columnIndexes:columnSet];
            break;
        case RBQFetchedResultsChangeMove:
            [self.callsTableView removeRowsAtIndexes:oldSet withAnimation:NSTableViewAnimationSlideLeft];
            [self.callsTableView insertRowsAtIndexes:newSet withAnimation:NSTableViewAnimationSlideRight];
            break;
    }
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    @try {
        [self.callsTableView endUpdates];
    }
    @catch (NSException *ex) {
        [controller reset];
        [self.callsTableView reloadData];
    }
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.callsController numberOfRowsForSectionIndex:0];
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
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];

    OCTCall *call = [self.callsController objectAtIndexPath:path];

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

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTCall *call = [self.callsController objectAtIndexPath:path];

    return call;
}

- (BOOL)doSomeThingWithCallWithBlock:(void (^)(OCTCall *))block
{
    NSInteger selectedRow = self.callsTableView.selectedRow;

    if (selectedRow < 0) {
        return NO;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTCall *call = [self.callsController objectAtIndexPath:path];

    block(call);

    return YES;
}

@end
