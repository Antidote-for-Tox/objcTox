// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTUserViewController.h"
#import "OCTSubmanagerUser.h"

typedef NS_ENUM(NSUInteger, Row) {
    RowConnectionStatus,
    RowAddress,
    RowPublicKey,
    RowNospam,
    RowStatus,
    RowName,
    RowStatusMessage,
};

static NSString *const kNibName = @"OCTUserViewController";
static NSString *const kTableViewIdentifier = @"userTableViewIdent";

@interface OCTUserViewController () <NSTableViewDataSource,
                                     NSTableViewDelegate,
                                     NSTextFieldDelegate,
                                     OCTSubmanagerUserDelegate>

@property (weak, nonatomic) id<OCTSubmanagerUser> userManager;
@property (weak) IBOutlet NSTableView *userTableView;
@property (strong, nonatomic) NSArray *userData;
@property (weak) IBOutlet NSTableColumn *firstColumn;
@property (weak) IBOutlet NSTableColumn *secondColumn;

@property (weak) IBOutlet NSImageView *avatarImageView;

@end

@implementation OCTUserViewController

- (instancetype)initWithManager:(id<OCTSubmanagerUser>)userManager
{
    self = [super initWithNibName:kNibName bundle:nil];

    if (! self) {
        return nil;
    }

    _userData = @[
        @(RowConnectionStatus),
        @(RowAddress),
        @(RowPublicKey),
        @(RowNospam),
        @(RowStatus),
        @(RowName),
        @(RowStatusMessage),
    ];

    _userManager = userManager;
    userManager.delegate = self;

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateAvatarImageView];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.userData.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *) tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row
{
    NSTextField *textField = [tableView makeViewWithIdentifier:kTableViewIdentifier owner:self];

    if (! textField) {
        textField = [NSTextField new];
        textField.identifier = kTableViewIdentifier;
    }

    if (tableColumn == self.firstColumn) {
        textField.stringValue = [self nameLabelForRow:row];
        textField.editable = NO;
    }

    if (tableColumn == self.secondColumn) {

        if (row == RowStatus) {
            NSPopUpButton *popUpButton = [NSPopUpButton new];
            popUpButton.tag = row;
            [popUpButton addItemsWithTitles:@[@"None", @"Away", @"Busy"]];
            [popUpButton selectItemAtIndex:self.userManager.userStatus];
            popUpButton.action = @selector(selectionMadeForUserStatus:);
            popUpButton.target = self;

            return popUpButton;
        }
        textField.stringValue = [self descriptionLabelForRow:row];
        textField.delegate = self;
        textField.selectable = (row < 3);
        textField.editable = (row >= 3);
    }

    return textField;
}

#pragma mark - NSButtonTargetAction

- (void)selectionMadeForUserStatus:(NSPopUpButton *)sender
{
    self.userManager.userStatus = sender.indexOfSelectedItem;
}

- (IBAction)avatarButtonPressed:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel runModal];

    NSString *path = [panel.URL path];
    NSData *data = [NSData dataWithContentsOfFile:path];

    [self.userManager setUserAvatar:data error:nil];
    [self updateAvatarImageView];
}

- (IBAction)removeAvatarButtonPressed:(id)sender
{
    [self.userManager setUserAvatar:nil error:nil];
    [self updateAvatarImageView];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    NSTextField *field = obj.object;

    NSInteger row = [self.userTableView rowForView:field];
    NSString *string = field.stringValue;
    switch (row) {
        case RowNospam:
            self.userManager.nospam = (OCTToxNoSpam)[string integerValue];
            break;
        case RowName:
            [self.userManager setUserName:string error:nil];
            break;
        case RowStatusMessage:
            [self.userManager setUserStatusMessage:string error:nil];
            break;
        default:
            break;
    }
}

#pragma mark -  OCTSubmanagerUserDelegate

- (void)submanagerUser:(nonnull id<OCTSubmanagerUser>)submanager connectionStatusUpdate:(OCTToxConnectionStatus)connectionStatus
{
    [self.userTableView reloadData];
}

#pragma mark - Private

- (NSString *)nameLabelForRow:(NSInteger)row
{
    NSString *label;
    switch (row) {
        case RowConnectionStatus:
            label = @"connectionStatus";
            break;
        case RowAddress:
            label = @"userAddress";
            break;
        case RowPublicKey:
            label = @"publicKey";
            break;
        case RowNospam:
            label = @"nospam";
            break;
        case RowStatus:
            label = @"user status";
            break;
        case RowName:
            label = @"userName";
            break;
        case RowStatusMessage:
            label = @"userStatusMessage";
            break;
        default:
            break;
    }

    return label;
}

- (NSString *)descriptionLabelForRow:(NSInteger)row
{
    NSString *label;
    switch (row) {
        case RowConnectionStatus:
            label = [self stringFromConnectionStatus:self.userManager.connectionStatus];
            break;
        case RowAddress:
            label = self.userManager.userAddress;
            break;
        case RowPublicKey:
            label = self.userManager.publicKey;
            break;
        case RowNospam:
            label = [NSString stringWithFormat:@"%u", self.userManager.nospam];
            break;
        case RowStatus:
            label = [self stringFromUserStatus:self.userManager.userStatus];
            break;
        case RowName:
            label = (self.userManager.userName) ? self.userManager.userName : @"";
            break;
        case RowStatusMessage:
            label = (self.userManager.userStatusMessage) ? self.userManager
                        .userStatusMessage : @"";
            break;
        default:
            break;
    }

    return label;
}


- (NSString *)stringFromConnectionStatus:(OCTToxConnectionStatus)status
{
    switch (status) {
        case OCTToxConnectionStatusNone:
            return @"None";
        case OCTToxConnectionStatusTCP:
            return @"TCP";
        case OCTToxConnectionStatusUDP:
            return @"UDP";
    }
}

- (NSString *)stringFromUserStatus:(OCTToxUserStatus)status
{
    switch (status) {
        case OCTToxUserStatusNone:
            return @"None";
        case OCTToxUserStatusAway:
            return @"Away";
        case OCTToxUserStatusBusy:
            return @"Busy";
    }
}

- (void)updateAvatarImageView
{
    self.avatarImageView.image = [[NSImage alloc] initWithData:self.userManager.userAvatar];
}

@end
