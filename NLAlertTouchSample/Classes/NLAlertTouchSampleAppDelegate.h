//
//  NLAlertTouchSampleAppDelegate.h
//  NLAlertTouchSample
//
//  Created by hkrn on 10/10/17.
//  Copyright hkrn 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NLAlertTouchSampleAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
    UIBackgroundTaskIdentifier backgroundTaskID;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end
