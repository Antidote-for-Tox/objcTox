//
//  OCTFilesViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFilesViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTManager.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerFiles.h"
#import "OCTSubmanagerFilesProgressSubscriber.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageFile.h"

static NSString *const kCellIdentifier = @"fileCell";

@interface OCTFilesViewController () <NSTableViewDataSource, NSTableViewDelegate, RBQFetchedResultsControllerDelegate,
                                      OCTSubmanagerFilesProgressSubscriber>

@property (weak, nonatomic) OCTManager *manager;
@property (weak) IBOutlet NSTableView *tableView;

@property (strong, nonatomic) RBQFetchedResultsController *filesController;

@end

@implementation OCTFilesViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageFile != nil"];
    RBQFetchRequest *fetchRequest = [manager.objects fetchRequestForType:OCTFetchRequestTypeMessageAbstract
                                                           withPredicate:predicate];

    _filesController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    _filesController.delegate = self;
    [_filesController performFetch];

    return self;
}

- (IBAction)receiveButtonPressed:(id)sender
{
    OCTMessageAbstract *message = [self messageForCurrentlySelectedRow];

    if (! message) {
        return;
    }

    [self.manager.files acceptFileTransfer:message failureBlock:nil];
    [self.manager.files addProgressSubscriber:self forFileTransfer:message error:nil];
}

- (IBAction)declineButtonPressed:(id)sender
{
    OCTMessageAbstract *message = [self messageForCurrentlySelectedRow];

    if (! message) {
        return;
    }

    [self.manager.files cancelFileTransfer:message error:nil];
}

- (IBAction)pauseButtonPressed:(id)sender
{
    OCTMessageAbstract *message = [self messageForCurrentlySelectedRow];

    if (! message) {
        return;
    }

    [self.manager.files pauseFileTransfer:YES message:message error:nil];
}

- (IBAction)resumeButtonPressed:(id)sender
{
    OCTMessageAbstract *message = [self messageForCurrentlySelectedRow];

    if (! message) {
        return;
    }

    [self.manager.files pauseFileTransfer:NO message:message error:nil];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.filesController numberOfRowsForSectionIndex:0];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 150.0;
}

#pragma mark - NSTableViewDataSource

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];

    OCTMessageAbstract *message = [self.filesController objectAtIndexPath:path];

    NSTextField *textField = [self.tableView makeViewWithIdentifier:kCellIdentifier owner:nil];

    if (! textField) {
        textField = [NSTextField new];
        textField.identifier = kCellIdentifier;
    }

    if ([tableColumn.identifier isEqualToString:@"AutomaticTableColumnIdentifier.0"]) {
        textField.stringValue = [NSString stringWithFormat:
                                 @"fileType = %@\n"
                                 @"pausedBy = %@\n"
                                 @"fileSize = %lld\n"
                                 @"fileName = %@\n"
                                 @"filePath = %@\n"
                                 @"fileUTI = %@\n"
                                 @"fileNumber = %d\n"
                                 @"sender = %@",
                                 [self stringFromFileType:message.messageFile.fileType],
                                 [self stringFromPausedBy:message.messageFile.pausedBy],
                                 message.messageFile.fileSize,
                                 message.messageFile.fileName,
                                 message.messageFile.filePath,
                                 message.messageFile.fileUTI,
                                 message.messageFile.internalFileNumber,
                                 message.sender];
    }
    else if ([tableColumn.identifier isEqualToString:@"AutomaticTableColumnIdentifier.1"]) {
        textField.stringValue = @"";
    }

    return textField;
}

#pragma mark -  RBQFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

#pragma mark -  OCTSubmanagerFilesProgressSubscriber

- (void)submanagerFilesOnProgressUpdate:(CGFloat)progress
                                message:(nonnull OCTMessageAbstract *)message
                         bytesPerSecond:(OCTToxFileSize)bytesPerSecond
                                    eta:(CFTimeInterval)eta
{
    NSIndexPath *indexPath = [self.filesController indexPathForObject:message];

    if (! indexPath) {
        [self.manager.files removeProgressSubscriber:self forFileTransfer:message error:nil];
        return;
    }

    NSTextField *textField = [self.tableView viewAtColumn:1 row:indexPath.row makeIfNecessary:NO];

    if (! textField) {
        return;
    }

    textField.stringValue = [NSString stringWithFormat:
                             @"progress = %.2f\n"
                             @"bytesPerSecond = %lld\n"
                             @"eta = %g",
                             progress,
                             bytesPerSecond,
                             eta];
}

#pragma mark -  Private

- (NSString *)stringFromFileType:(OCTMessageFileType)type
{
    switch (type) {
        case OCTMessageFileTypeWaitingConfirmation:
            return @"Waiting confirmaion";
        case OCTMessageFileTypeLoading:
            return @"Loading";
        case OCTMessageFileTypePaused:
            return @"Paused";
        case OCTMessageFileTypeCanceled:
            return @"Canceled";
        case OCTMessageFileTypeReady:
            return @"Ready";
    }
}

- (NSString *)stringFromPausedBy:(OCTMessageFilePausedBy)pausedBy
{
    if (pausedBy == OCTMessageFilePausedByNone) {
        return @"None";
    }

    NSString *string = @"";

    if (pausedBy & OCTMessageFilePausedByUser) {
        string = [string stringByAppendingString:@" user"];
    }

    if (pausedBy & OCTMessageFilePausedByFriend) {
        string = [string stringByAppendingString:@" friend"];
    }

    return string;
}

- (OCTMessageAbstract *)messageForCurrentlySelectedRow
{
    NSInteger selectedRow = self.tableView.selectedRow;

    if (selectedRow < 0) {
        return nil;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTMessageAbstract *message = [self.filesController objectAtIndexPath:path];

    return message;
}

@end
