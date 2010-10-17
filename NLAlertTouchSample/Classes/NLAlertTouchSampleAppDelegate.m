//
//  NLAlertTouchSampleAppDelegate.m
//  NLAlertTouchSample
//
//  Created by hkrn on 10/10/17.
//  Copyright hkrn 2010. All rights reserved.
//

#import "NLAlertTouchSampleAppDelegate.h"
#import "RootViewController.h"

@implementation NLAlertTouchSampleAppDelegate

@synthesize window;
@synthesize navigationController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}

@end
