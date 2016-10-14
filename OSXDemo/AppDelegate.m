// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "AppDelegate.h"
#import "OCTMainWindowController.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

@interface AppDelegate ()

@property (strong, nonatomic) IBOutlet OCTMainWindowController *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    self.window = [[OCTMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
    [self.window showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

@end
