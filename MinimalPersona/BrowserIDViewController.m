/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "AFNetworkActivityIndicatorManager.h"
#import "BrowserIDClient.h"
#import "BrowserIDViewController.h"
#import "RPSTPasswordManagementAppService.h"

static NSString* const kBrowserIDSignInURL = @"https://login.persona.org/sign_in#NATIVE";

@interface BrowserIDViewController () <BrowserIDViewControllerDelegate, UIWebViewDelegate>

@property (strong) BrowserIDClient* client;
@property (weak) id<BrowserIDViewControllerDelegate> delegate;
@property (strong) UIWebView* webView;

@end

#pragma mark -

@implementation BrowserIDViewController

- (id)init {
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Mozilla Persona", @"Mozilla Persona");
    
    if ([RPSTPasswordManagementAppService passwordManagementAppIsAvailable]) {
        NSString* displayName = [RPSTPasswordManagementAppService availablePasswordManagementAppDisplayName];
        UIImage* displayImage = nil;
        
        switch ([RPSTPasswordManagementAppService availablePasswordManagementApp]) {
            case RPSTPasswordManagementAppType1Password_v3:
                displayImage = [UIImage imageNamed:@"onePassword_v3"];
                break;
            case RPSTPasswordManagementAppType1Password_v4:
                displayImage = [UIImage imageNamed:@"onePassword_v4"];
                break;
            default:
                break;
        }
        
        if (displayImage) {
            UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.accessibilityLabel = displayName;
            button.frame = CGRectMake(0.0, 0.0, displayImage.size.width, displayImage.size.height);
            [button addTarget:self action:@selector(openPasswordApp) forControlEvents:UIControlEventTouchUpInside];
            [button setImage:displayImage forState:UIControlStateNormal];
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        } else {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:displayName
                                                                                     style:UIBarButtonItemStylePlain
                                                                                    target:self
                                                                                    action:@selector(openPasswordApp)];
        }
    }
        
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:NSLocalizedString(@"Cancel", @"Mozilla Persona")
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(cancel)];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kBrowserIDSignInURL]]];
}

#pragma mark -

- (void)cancel {
    [self.webView stopLoading];
    [self.delegate browserIDViewControllerDidCancel:self];
}

- (void)openPasswordApp {
    NSURL* url = [RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"persona.org"];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - BrowserIDViewController delegate methods

- (void)browserIDViewController:(BrowserIDViewController *)browserIDViewController didFailWithReason:(NSString *)reason {
    [self browserIDViewControllerDidCancel:browserIDViewController];
}

- (void)browserIDViewController:(BrowserIDViewController *)browserIDViewController
        didSucceedWithAssertion:(NSString *)assertion {
    [self browserIDViewControllerDidCancel:browserIDViewController];
    
    NSURL* baseURL = [NSURL URLWithString:browserIDViewController.origin];
    self.client = [[BrowserIDClient alloc] initWithBaseURL:baseURL
                                              callbackPath:browserIDViewController.callbackPath
                                                 loginPath:browserIDViewController.loginPath];
    [self.client loginWithPersonaAssertion:assertion completionHandler:self.cookieHandler];
}

- (void)browserIDViewControllerDidCancel:(BrowserIDViewController *)browserIDViewController {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 6000
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
#else
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
#endif
}

#pragma mark - UIWebView delegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* url = [request URL];
    
	// The JavaScript side (the code injected in viewDidLoad will make callbacks to this native code by requesting
	// a BrowserIDViewController://callbackname/callback?data=foo style URL. So we capture those here and relay
	// them to our delegate.
	
	if ([[[url scheme] lowercaseString] isEqualToString:@"browseridviewcontroller"]) {	
		if ([[url host] isEqualToString:@"assertionReady"]) {
			[self.delegate browserIDViewController:self didSucceedWithAssertion: [[url query]
                                                                                  substringFromIndex:[@"data=" length]]];
		}
		
		else if ([[url host] isEqualToString:@"assertionFailure"]) {
			[self.delegate browserIDViewController:self didFailWithReason:[[url query] substringFromIndex:[@"data=" length]]];
		}
	
		return NO;
	}
    	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    [self.webView loadHTMLString:error.localizedDescription baseURL:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    
	// Insert the code that will setup and handle the BrowserID callback.

	NSString* injectedCodePath = [[NSBundle mainBundle] pathForResource:@"BrowserIDViewController" ofType:@"js"];
	NSString* injectedCodeTemplate = [NSString stringWithContentsOfFile:injectedCodePath encoding:NSUTF8StringEncoding error:nil];
	NSString* injectedCode = [NSString stringWithFormat:injectedCodeTemplate, self.origin];

	[self.webView stringByEvaluatingJavaScriptFromString: injectedCode];
}

@end
