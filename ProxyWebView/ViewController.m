//
//  ViewController.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//

#import "ViewController.h"

@interface ViewController () <WKUIDelegate, WKNavigationDelegate, WKURLSchemeHandler, WKScriptMessageHandler>

@property (strong, nonatomic) WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self createWebView];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self navigateTo:@"http://padlet.com/"];
  [self testLocalServer];
}

- (void)testLocalServer {
  NSLog(@"[ViewController] testing local server!");
  
  NSURL *url = [NSURL URLWithString:@"http://0.0.0.0:8888"];
  NSString *hello = [NSString stringWithFormat:@"Hello, world!"];
  NSData *data = [hello dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setValue:@"text/*" forHTTPHeaderField:@"Accept"];
  [request setHTTPBody:data];
  
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
  [task resume];
}

#pragma mark - Navigation


- (void)navigateTo:(NSString *)urlString {
  NSLog(@"[ViewController] navigating to: \"%@\"", urlString);
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [self.webView loadRequest:request];
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction preferences:(WKWebpagePreferences *)preferences decisionHandler:(void (^)(WKNavigationActionPolicy, WKWebpagePreferences * _Nonnull))decisionHandler {
  NSLog(@"[ViewController] decidePolicyForNavigationAction (with preferences) for %@", navigationAction.request.URL.absoluteString);
  decisionHandler(WKNavigationActionPolicyAllow, preferences);
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSLog(@"[ViewController] decidePolicyForNavigationAction for %@", navigationAction.request.URL.absoluteString);
  decisionHandler(WKNavigationActionPolicyAllow);
}



#pragma mark - Initialization


- (void)createWebView {
  NSLog(@"[ViewController] creating webview!");
  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
  
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"70041E16-0B3D-497C-8051-CD4115FB3F27"];
  WKWebsiteDataStore *store = [WKWebsiteDataStore dataStoreForIdentifier:uuid];
  NSLog(@"[ViewController] store loaded (%@) uuid: %@", store.description, uuid);
  
  WKPreferences *preferences = [[WKPreferences alloc] init];
  preferences.inactiveSchedulingPolicy = WKInactiveSchedulingPolicyNone;
    
  WKWebpagePreferences *pagePrefs = [[WKWebpagePreferences alloc] init];
  pagePrefs.allowsContentJavaScript = true;
    
  WKUserContentController *controller = [[WKUserContentController alloc] init];
  
  // [configuration setURLSchemeHandler:self forURLScheme:@"https"];
    
  // setup configuration
  configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
  configuration.allowsPictureInPictureMediaPlayback = true;
  configuration.suppressesIncrementalRendering = false;
  configuration.allowsAirPlayForMediaPlayback = true;
  configuration.allowsInlineMediaPlayback = true;
  
  // setup process pool
  WKProcessPool *pool = [[WKProcessPool alloc] init];
  
  // configure preferences and controllers
  configuration.defaultWebpagePreferences = pagePrefs;
  configuration.userContentController = controller;
  configuration.preferences = preferences;
  configuration.processPool = pool;

  self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
  [self.view addSubview:self.webView];
}


#pragma mark - Script Handler


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
  NSLog(@"[ViewController] didReceiveScriptMessage: %@", message);
}


#pragma mark - Scheme Handler


- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
  NSLog(@"[ViewController] startURLSchemeTask: %@", urlSchemeTask.description);
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask { 
  NSLog(@"[ViewController] stopURLSchemeTask: %@", urlSchemeTask.description);
}

@end
