//
//  Config.h
//  ProxyWebView
//
//  Created by Colin Teahan on 5/24/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
  kSERVER_MODE_LOCAL,
  kSERVER_MODE_REMOTE_INSECURE,
  kSERVER_MODE_REMOTE_SECURE,
} kSERVER_MODE;

@interface Config : NSObject

+ (void)info;

@property (class, readonly) kSERVER_MODE MODE;

@property (class, assign, nonatomic, readonly) const char *HTTPS_ENDPOINT;
@property (class, assign, nonatomic, readonly) const char *HTTP_ENDPOINT;

@property (class, assign, nonatomic, readonly) const char *HOST;
@property (class, assign, nonatomic, readonly) const char *PORT;

@property (class, readonly) BOOL ENABLE_URL_PROXY;
@property (class, readonly) BOOL ENABLE_PEER_2_PEER;
@property (class, readonly) BOOL ENABLE_LOCAL_ONLY;
@property (class, readonly) BOOL ENABLE_REUSE_ADDRESS;
@property (class, readonly) BOOL ENABLE_FAST_OPEN;

@end

NS_ASSUME_NONNULL_END
