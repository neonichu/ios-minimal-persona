/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

typedef void(^BrowserIDCookieHandler)(NSArray* cookies, NSError* error);

@class BrowserIDViewController;

@protocol BrowserIDViewControllerDelegate <NSObject>

- (void)browserIDViewController:(BrowserIDViewController*)browserIDViewController didFailWithReason:(NSString*)reason;
- (void)browserIDViewController:(BrowserIDViewController*)browserIDViewController didSucceedWithAssertion:(NSString*)assertion;
- (void)browserIDViewControllerDidCancel:(BrowserIDViewController*)browserIDViewController;

@end

#pragma mark -

@interface BrowserIDViewController : UIViewController

@property (strong) NSString* callbackPath;
@property (copy) BrowserIDCookieHandler cookieHandler;
@property (strong) NSString* loginPath;
@property (strong) NSString* origin;

@end
