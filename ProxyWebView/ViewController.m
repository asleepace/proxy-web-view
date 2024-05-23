//
//  ViewController.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//
//  Associated domains:
//  https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content
//
//

#import "ViewController.h"
#import "CertBot.h"

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
  // [self navigateTo:@"http://padlet.com/"];
  // [self testLocalServer];
  
  // fonts work with local HTML
  [self loadHTML:@"index"];
  
  // only works with HTTP
  // [self navigateTo: @"http://dlabs.me/test/example.html"];
  
  // we need to sign for TLS to work
//  [self navigateTo: @"http://dlabs.me/test/example.html"];
}

- (void)loadHTML:(NSString *)localFile {
  NSLog(@"[ProxyWebView] loading HTML from local file...");
  NSURL *url = [[NSBundle mainBundle] URLForResource:localFile withExtension:@"html"];
  [self.webView loadFileURL:url allowingReadAccessToURL:url];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [self.webView loadRequest:request];
}

//  Send a test message to the local server
//  although this will fail.
//
- (void)testLocalServer {
  NSLog(@"[ViewController] testing local server!");
  NSURL *url = [NSURL URLWithString:@"http://0.0.0.0:8888"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setValue:@"text/*" forHTTPHeaderField:@"Accept"];
  [request setHTTPMethod:@"GET"];
//  [request setHTTPBody:data];
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
  [preferences setValue:@"TRUE" forKey:@"allowFileAccessFromFileURLs"];

    
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
  [self.webView setInspectable:true];
  self.webView.navigationDelegate = self;
  self.webView.UIDelegate = self;
  
  [self.view addSubview:self.webView];
}


#pragma mark - Authentication


- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
  NSLog(@"[ViewController] did receive challenge: %@", challenge);
  
  [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    SecCertificateRef selfSignedCertificate = [[CertBot shared] getCertificate];
    [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
  }];
}

- (void)webView:(WKWebView *)webView authenticationChallenge:(NSURLAuthenticationChallenge *)challenge shouldAllowDeprecatedTLS:(void (^)(BOOL))decisionHandler {
  NSLog(@"[ViewController] webView authenticationChallenge: %@", challenge.description);
  decisionHandler(true);
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
