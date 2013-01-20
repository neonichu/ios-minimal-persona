//
//  AppDelegate.m
//  MinimalPersona
//
//  Created by Stefan Arentz on 2012-08-03.
//
//

#import "AppDelegate.h"
#import "BrowserIDViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [UIViewController new];
    self.window.rootViewController.view.backgroundColor = [UIColor lightGrayColor];
    [self.window makeKeyAndVisible];
    
    BrowserIDViewController* browserIdVC = [BrowserIDViewController new];
    browserIdVC.callbackPath = @"/auth/browser_id/callback";
    browserIdVC.loginPath = @"/login";
    browserIdVC.origin = @"http://sloblog.io";
    
    browserIdVC.cookieHandler = ^(NSArray* cookies, NSError* error) {
        if (!cookies) {
            NSLog(@"Error: %@", error.localizedDescription);
            return;
        }
        
        NSLog(@"Cookies: %@", cookies);
    };
    
    UINavigationController* subNav = [[UINavigationController alloc] initWithRootViewController:browserIdVC];
    [self.window.rootViewController presentModalViewController:subNav animated:NO];
    return YES;
}






@end
