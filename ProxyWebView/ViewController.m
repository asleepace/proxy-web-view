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
  // [self loadHTML:@"index"];
  
  // only works with HTTP
  // [self navigateTo: @"http://dlabs.me/test/example.html"];
  
  // we need to sign for TLS to work
  [self clearCookiesForURL:@"https://dlabs.me/test/example.html"];
  [self navigateTo: @"https://dlabs.me/test/example.html"];
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

//  NOTE: Seems to skip auth challenge
//- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
//  NSLog(@"[WKAuth] didStartProvisionalNavigation: %@", navigation);
//}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
  NSLog(@"[WKAuth] did receive challenge: %@", challenge);
  
  //  NOTE: This will cause all challenges to succeed
  NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
  [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
  completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
  return;
  

  if (![challenge.protectionSpace.host containsString:@"0.0.0.0"]) {
    NSLog(@"[WKAuth] host contains different string: %@", challenge.protectionSpace.host);
    NSLog(@"[WkAuth] using default challenge with proposed credential: %@", challenge.proposedCredential);
    NSLog(@"[WkAuth] currently with the server trust: %@", challenge.protectionSpace.serverTrust);
    //[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, challenge.proposedCredential);
    return;
  }
  
  [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    NSLog(@"[WKAuth] loaded credentials: %@", credential);
    NSLog(@"[WKAuth] protectionSpace: %@", challenge.protectionSpace);
    NSLog(@"[WKAuth] serverTrust: %@", challenge.protectionSpace.serverTrust);
    
    if (!credential) {
      SecCertificateRef selfSignedCert = [[CertBot shared] getCertificate];
      NSLog(@"[WKAuth] credential not found, creating!");

      SecIdentityRef identityRef = NULL;
      OSStatus status = SecIdentityCopyCertificate(identityRef, &selfSignedCert);
      credential = [[NSURLCredential alloc] initWithIdentity:identityRef 
                                                certificates:@[]
                                                 persistence:NSURLCredentialPersistenceForSession];
    }
    
    SecCertificateRef selfSignedCert = [[CertBot shared] getCertificate];
    [credential.certificates arrayByAddingObject:CFBridgingRelease(selfSignedCert)];
        
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


#pragma mark - Clear Cookies

- (void)clearCookiesForURL:(NSString *)urlString {
  NSURL *URL = [NSURL URLWithString:urlString];
  NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray *cookies = [cookieStorage cookiesForURL:URL];
  for (NSHTTPCookie *cookie in cookies) {
    NSLog(@"[AuthWebView] deleting cookie for domain: %@", [cookie domain]);
    [cookieStorage deleteCookie:cookie];
  }
}

@end
