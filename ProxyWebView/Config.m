//
//  Config.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/24/24.
//

#import "Config.h"

@implementation Config

+ (kSERVER_MODE)MODE {
  //return kSERVER_MODE_REMOTE_INSECURE;
  //return kSERVER_MODE_REMOTE_SECURE;
  return kSERVER_MODE_LOCAL;
}

+ (const char *)HTTPS_ENDPOINT {
  return [[NSString stringWithFormat:@"https://%s:%s", Config.HOST, Config.PORT] cStringUsingEncoding:NSUTF8StringEncoding];
}

+ (const char *)HTTP_ENDPOINT {
  return [[NSString stringWithFormat:@"http://%s:%s", Config.HOST, Config.PORT] cStringUsingEncoding:NSUTF8StringEncoding];
}

+ (const char *)HOST { return "0.0.0.0"; }
+ (const char *)PORT { return "8888"; }

//  NOTE: These seem to work for both true or false values,
//  when using local html.
//
+ (BOOL)ENABLE_PEER_2_PEER    { return true;  }
+ (BOOL)ENABLE_FAST_OPEN      { return true;  }

//  NOTE: This causes the local index.html file to even fail.
//  Please keep this as false.
//
+ (BOOL)ENABLE_LOCAL_ONLY     { return false; }

//  URL PROTOCOL
//
+ (BOOL)ENABLE_URL_PROXY      { return false; }

//  DEFAULTS TRUE
//
+ (BOOL)ENABLE_REUSE_ADDRESS  { return true;  }

//  DEBUGGING ONLY
//  Display environment configuration to the programmer for easier debugging.
//
+ (void)info {
  NSLog(@"+ - + - + - + - + - + - + - + - + - + - +");
  NSLog(@"\tHTTPS_ENDPOINT: %s", Config.HTTPS_ENDPOINT);
  NSLog(@"\tHTTP_ENDPOINT: %s", Config.HTTP_ENDPOINT);
  NSLog(@"\tENABLE_REUSE_ADDRESS: %s", Config.ENABLE_PEER_2_PEER ? "YES" : "NO");
  NSLog(@"\tENABLE_PEER_2_PEER: %s", Config.ENABLE_PEER_2_PEER ? "YES" : "NO");
  NSLog(@"\tENABLE_LOCAL_ONLY: %s", Config.ENABLE_LOCAL_ONLY ? "YES" : "NO");
  NSLog(@"\tENABLE_FAST_OPEN: %s", Config.ENABLE_FAST_OPEN ? "YES" : "NO");
  NSLog(@"\tENABLE_URL_PROXY: %s", Config.ENABLE_URL_PROXY ? "YES" : "NO");
  NSLog(@"\tHOST: %s", Config.HOST);
  NSLog(@"\tPORT: %s", Config.PORT);
  NSLog(@"+ - + - + - + - + - + - + - + - + - + - +");
}

@end
