//
//  RootViewController.h
//  NLNotification
//
//  Created by hkrn on 10/10/11.
//  Copyright hkrn 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OCNLN/OCNLN.h>

@interface RootViewController : UITableViewController<UIAlertViewDelegate> {
@private
    NLNAuthentication *authentication;
    NLNUserLoader *userLoader;
    NLNThreadConnection *threadConnection;
    NLNUser *user;
    NSMutableArray *streams;
    NSTimeInterval lastModified;
}

@end
