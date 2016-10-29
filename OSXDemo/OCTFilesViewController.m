// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTFilesViewController.h"
#import "OCTManager.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerFiles.h"
#import "OCTSubmanagerFilesProgressSubscriber.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageFile.h"

static NSString *const kCellIdentifier = @"fileCell";

@interface OCTFilesViewController () <NSTableViewDataSource, NSTableViewDelegate, OCTSubmanagerFilesProgressSubscriber>

@property (weak, nonatomic) id<OCTManager> manager;
@property (weak) IBOutlet NSTableView *tableView;

@property (strong, nonatomic) RLMResults<OCTMessageAbstract *> *fileMessages;
@property (strong, nonatomic) RLMNotificationToken *fileMessagesNotificationToken;

@end

@implementation OCTFilesViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(id<OCTManager>)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageFile != nil"];
    _fileMessages = [manager.objects objectsForType:OCTFetchRequestTypeMessageAbstract predicate:predicate];

    return self;
}

- (void)dealloc
{
    [self.fileMessagesNotificationToken stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.fileMessagesNotificationToken = [self.fileMessages addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        [weakSelf.tableView reloadData];
    }];
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
    return self.fileMessages.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 150.0;
}

#pragma mark - NSTableViewDataSource

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    OCTMessageAbstract *message = self.fileMessages[row];

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
                                 @"senderUniqueIdentifier = %@",
                                 [self stringFromFileType:message.messageFile.fileType],
                                 [self stringFromPausedBy:message.messageFile.pausedBy],
                                 message.messageFile.fileSize,
                                 message.messageFile.fileName,
                                 message.messageFile.filePath,
                                 message.messageFile.fileUTI,
                                 message.messageFile.internalFileNumber,
                                 message.senderUniqueIdentifier];
    }
    else if ([tableColumn.identifier isEqualToString:@"AutomaticTableColumnIdentifier.1"]) {
        textField.stringValue = @"";
    }

    return textField;
}

#pragma mark -  OCTSubmanagerFilesProgressSubscriber

- (void)submanagerFilesOnProgressUpdate:(float)progress message:(nonnull OCTMessageAbstract *)message
{}

- (void)submanagerFilesOnEtaUpdate:(CFTimeInterval)eta
                    bytesPerSecond:(OCTToxFileSize)bytesPerSecond
                           message:(nonnull OCTMessageAbstract *)message
{
    NSUInteger index = [self.fileMessages indexOfObject:message];

    if (index == NSNotFound) {
        [self.manager.files removeProgressSubscriber:self forFileTransfer:message error:nil];
        return;
    }

    NSTextField *textField = [self.tableView viewAtColumn:1 row:index makeIfNecessary:NO];

    if (! textField) {
        return;
    }

    textField.stringValue = [NSString stringWithFormat:
                             @"bytesPerSecond = %lld\n"
                             @"eta = %g",
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

    OCTMessageAbstract *message = self.fileMessages[selectedRow];

    return message;
}

@end
