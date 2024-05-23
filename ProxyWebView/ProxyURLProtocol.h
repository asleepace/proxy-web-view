//
//  ProxyURLProtocol.h
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProxyURLProtocol : NSURLProtocol<NSURLSessionDelegate>

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;

- (void)startLoading;
- (void)stopLoading;

@end

NS_ASSUME_NONNULL_END
