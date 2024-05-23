//
//  LocalServer.h
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalServer : NSObject

+ (LocalServer *)createLocalHTTPServer;

- (id)init;
- (void)startServer;

@end

NS_ASSUME_NONNULL_END
