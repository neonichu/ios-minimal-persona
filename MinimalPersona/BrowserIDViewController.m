/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "BrowserIDClient.h"
#import "BrowserIDViewController.h"

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
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
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

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// Insert the code that will setup and handle the BrowserID callback.

	NSString* injectedCodePath = [[NSBundle mainBundle] pathForResource:@"BrowserIDViewController" ofType:@"js"];
	NSString* injectedCodeTemplate = [NSString stringWithContentsOfFile:injectedCodePath encoding:NSUTF8StringEncoding error:nil];
	NSString* injectedCode = [NSString stringWithFormat:injectedCodeTemplate, self.origin];

	[self.webView stringByEvaluatingJavaScriptFromString: injectedCode];
}

@end
