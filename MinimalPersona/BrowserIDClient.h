//
//  BrowserIDClient.h
//  MinimalPersona
//
//  Created by Boris Bügling on 20.01.13.
//
//

#import "AFHTTPClient.h"

@interface BrowserIDClient : AFHTTPClient

-(id)initWithBaseURL:(NSURL*)baseURL callbackPath:(NSString*)callbackPath loginPath:(NSString*)loginPath;
-(void)loginWithPersonaAssertion:(NSString*)assertion completionHandler:(void(^)(NSArray* cookies, NSError* error))block;

@end
