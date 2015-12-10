//
//  AppDelegate.m
//  OSXDemo
//
//  Created by Dmytro Vorobiov on 19/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

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
