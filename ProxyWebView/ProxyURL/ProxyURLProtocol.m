//
//  ProxyURLProtocol.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//
//  About proxies: https://forums.developer.apple.com/forums/thread/19356

#import <Foundation/Foundation.h>
#import "ProxyURLProtocol.h"
#import <Network/Network.h>
#import <CFNetwork/CFProxySupport.h>
#import "Config.h"


@interface ProxyURLProtocol() <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation ProxyURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
  // if (Config.ENABLE_URL_PROXY == false) return false;
  
  NSLog(@"[ProxyURLProtocol] canInitWithRequest: %@", request.URL.absoluteString);
  // Only handle http and https requests
  NSString *scheme = [[request URL] scheme];
  return ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  NSLog(@"[ProxyURLProtocol] canonicalRequestForRequest %@", request.URL.absoluteURL);
  return request;
}

- (void)startLoading {
  NSLog(@"[ProxyURLProtocol] started loading...");
  NSMutableURLRequest *newRequest = [[self request] mutableCopy];
  
  //  About Proxy Settings
  //  https://stackoverflow.com/questions/36333784/programmatically-configure-proxy-settings-in-ios
  //
  NSDictionary *proxyDict = @{
    @"HTTPSEnable": @1,
    @"HTTPSProxy": @"0.0.0.0",
    @"HTTPSPort": @8888,
    (NSString *)kCFNetworkProxiesHTTPEnable: @1,
    (NSString *)kCFNetworkProxiesHTTPProxy: @"0.0.0.0",
    (NSString *)kCFNetworkProxiesHTTPPort: @8888,
    //  DEPRECATED: add proxy settings to the request
//    (NSString *)kCFStreamPropertyHTTPProxyHost: @"0.0.0.0",
//    (NSString *)kCFStreamPropertyHTTPProxyPort: @8888,
//    (NSString *)kCFStreamPropertyHTTPSProxyHost: @"0.0.0.0",
//    (NSString *)kCFStreamPropertyHTTPSProxyPort: @8888
  };
  

  
//  [newRequest setAllHTTPHeaderFields:proxyDict];
  
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  config.connectionProxyDictionary = proxyDict;
  
  NSOperationQueue *delegateQueue = [[NSOperationQueue alloc] init];
  
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:delegateQueue];
  
  NSLog(@"[ProxyURLProtocol] starting dataTask!");
  self.dataTask = [session dataTaskWithRequest:newRequest completionHandler:
                   ^(NSData *data, NSURLResponse *response, NSError *error) {
    NSLog(@"[ProxyURLProtocol] dataTask with data: %@ error: %@", data, error);
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    }
  }];
  [self.dataTask resume];
}

- (void)stopLoading {
  NSLog(@"[ProxyURLProtocol] stop loading!");
  [self.dataTask cancel];
  self.dataTask = nil;
}

@end

