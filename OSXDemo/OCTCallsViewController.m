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
                             call.friendSendingVideo, call.friendAcceptingVideo];;

    return textField;
}

#pragma mark - Actions

- (IBAction)callActionButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.callsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTCall *call = [self.callsController objectAtIndexPath:path];


    [self.manager.calls answerCall:call enableAudio:YES enableVideo:NO error:nil];
}

- (IBAction)sendCallControlSelected:(NSPopUpButton *)sender
{
    NSInteger selectedRow = self.callsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTCall *call = [self.callsController objectAtIndexPath:path];

    OCTToxAVCallControl control = (OCTToxAVCallControl)[sender indexOfSelectedItem];

    [self.manager.calls sendCallControl:control toCall:call error:nil];
}

@end
