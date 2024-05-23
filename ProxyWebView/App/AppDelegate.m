//
//  AppDelegate.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//

#import "AppDelegate.h"
#import "ProxyURLProtocol.h"
#import "LocalServer.h"

@interface AppDelegate ()

@property (strong, nonatomic) LocalServer *server;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [NSURLProtocol registerClass:[ProxyURLProtocol class]]; // register custom proxy
  
  // start local http server
  self.server = [LocalServer createLocalHTTPServer];
  
  return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
  // Called when a new scene session is being created.
  // Use this method to select a configuration to create the new scene with.
  return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
  // Called when the user discards a scene session.
  // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
  // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
