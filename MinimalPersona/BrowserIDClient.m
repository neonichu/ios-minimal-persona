//
//  BrowserIDClient.m
//  MinimalPersona
//
//  Created by Boris Bügling on 20.01.13.
//
//

#import "AFNetworking.h"
#import "BrowserIDClient.h"

@interface BrowserIDClient ()

@property (strong) NSString* callbackPath;
@property (strong) NSString* loginPath;
@property (strong) NSMutableArray* uselessCookies;

@end

#pragma mark -

@implementation BrowserIDClient

-(void)callbackWithPersonaAssertion:(NSString*)assertion completionHandler:(void (^)(NSArray *, NSError *))block {
    [self postPath:self.callbackPath parameters:@{ @"assertion": assertion }
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               block([self filteredCookies], nil);
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               block(nil, error);
           }];
}

-(NSArray*)filteredCookies {
    NSMutableArray* cookies = [NSMutableArray array];
    for (NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        if (![self.uselessCookies containsObject:cookie.name]) {
            [cookies addObject:cookie];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
    return [cookies copy];
}

-(id)initWithBaseURL:(NSURL *)baseURL callbackPath:(NSString *)callbackPath loginPath:(NSString *)loginPath {
    self = [super initWithBaseURL:baseURL];
    if (self) {
        self.callbackPath = callbackPath;
        self.loginPath = loginPath;
        self.uselessCookies = [NSMutableArray arrayWithObject:@"login.persona.org"];
    }
    return self;
}

-(void)loginWithPersonaAssertion:(NSString *)assertion completionHandler:(void (^)(NSArray *, NSError *))block {
    if (!block) {
        return;
    }
    
    for (NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [self.uselessCookies addObject:cookie.name];
    }
    
    [self getPath:self.loginPath parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              [self callbackWithPersonaAssertion:assertion completionHandler:block];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              block(nil, error);
          }];
}

-(NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableURLRequest* request = [super requestWithMethod:method path:path parameters:parameters];
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:request.allHTTPHeaderFields];
    
    NSDictionary* cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:[[NSHTTPCookieStorage sharedHTTPCookieStorage]
                                                                                cookies]];
    [headers addEntriesFromDictionary:cookieHeaders];
    
    headers[@"Referer"] = [self.baseURL.absoluteString stringByAppendingPathComponent:self.loginPath];
    
    [request setAllHTTPHeaderFields:headers];
    return request;
}

@end
