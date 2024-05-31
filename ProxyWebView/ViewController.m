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

#import <WebKit/WKURLSchemeHandler.h>
#import "ViewController.h"
#import "FileProxy.h"
#import "CertBot.h"
#import "Config.h"
#import "HTML.h"

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
  
  //  NOTE: Issue with provisional navigation
  //  https://stackoverflow.com/questions/71678158/didfailprovisionalloadforframe-for-certain-url-but-works-fine-in-safari
  
  //  NOTE: UDP hole punching may fix an issue with physical devices
  if (Config.ENABLE_UDP_HOLE_PUNCH) [self holePunch:Config.HTTPS_ENDPOINT];
  
  //  NOTE: May fix a bug with stale certificates
  //  [self clearCookiesForURL:@"https://dlabs.me/test/example.html"];
  
  //  NOTE: Load content for mode
  [[NSTimer timerWithTimeInterval:5.0 repeats:false block:^(NSTimer * timer) {
    NSLog(@"[ViewController] begin with mode!");
    [self beginWithMode];
  }] fire];
}

//  NOTE: This is to quickly test the three different modes.
//  Ideally we want remote secure to work, the others are
//  useful for quickly debugging other items.
//
- (void)beginWithMode {
  switch (Config.MODE) {
    case kSERVER_MODE_LOCAL: {
      NSLog(@"[ViewController] SERVER MODE LOCAL");
      NSString *localHtmlFile = [HTML generate];
      [self loadHTML:localHtmlFile];
      return;
    }
    case kSERVER_MODE_REMOTE_INSECURE: {
      NSLog(@"[ViewController] SERVER MODE REMOTE INSECURE");
      [self navigateTo: @"http://dlabs.me/test/example.html"];
      return;
    }
    case kSERVER_MODE_REMOTE_SECURE: {
      NSLog(@"[ViewController] SERVER MODE REMOTE SECURE");
//      [self navigateTo: @"https://dlabs.me/test/example.html"];
      [self navigateTo:@"https://padlet.com/asleepace/my-fierce-wall-ny26t0vshcli"];
    }
  }
}



- (void)loadHTML:(NSString *)localFile {
  NSLog(@"[ProxyWebView] loading HTML from local file: %@", localFile);
  NSURL *url = [NSURL fileURLWithPath:localFile];
  //NSURL *url = [[NSBundle mainBundle] URLForResource:localFile withExtension:@"html"];
  [self.webView loadFileURL:url allowingReadAccessToURL:url];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [self.webView loadRequest:request];
}

//  NOTE: This method may help UDP hole punch to open a connection window
//  to the remote server. Expect this to fail for TLS.
//
- (void)holePunch:(const char *)endpoint {
  NSLog(@"[ViewController] hole punching: %s", endpoint);
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%s", endpoint]];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [request setHTTPMethod:@"HEAD"];
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
  [preferences setInactiveSchedulingPolicy:WKInactiveSchedulingPolicyThrottle];
    
  WKWebpagePreferences *pagePrefs = [[WKWebpagePreferences alloc] init];
  pagePrefs.allowsContentJavaScript = true;
    
  WKUserContentController *controller = [[WKUserContentController alloc] init];
  
  // setup wkscheme handler
  [configuration setURLSchemeHandler:self forURLScheme:@"app"];
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
  NSLog(@"[WKAuth] url: %@", challenge.protectionSpace.);
  
//  //  NOTE: This will cause all challenges to succeed
//  NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
//  [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
//  completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
//  return;
//  
//
//  if (![challenge.protectionSpace.host containsString:@"0.0.0.0"]) {
//    NSLog(@"[WKAuth] host contains different string: %@", challenge.protectionSpace.host);
//    NSLog(@"[WkAuth] using default challenge with proposed credential: %@", challenge.proposedCredential);
//    NSLog(@"[WkAuth] currently with the server trust: %@", challenge.protectionSpace.serverTrust);
//    //[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
//    [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
//    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, challenge.proposedCredential);
//    return;
//  }
  
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
      
      NSLog(@"[WKAuth] security identity copy certificate state: %u", status);
      
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
  NSLog(@"[ViewController] webView authenticationChallenge: %@", challenge.protectionSpace);
  decisionHandler(true);
}


#pragma mark - Provisional navigation

//  NOTE: https://stackoverflow.com/questions/71678158/didfailprovisionalloadforframe-for-certain-url-but-works-fine-in-safari
//  See .plist exception domains
//
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
  NSLog(@"[ViewController] didFailProvisionalNavigation %@", error);
  [webView reload];
}



#pragma mark - Script Handler


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
  NSLog(@"[ViewController] didReceiveScriptMessage: %@", message);
}


#pragma mark - Scheme Handler


- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
  NSLog(@"[ViewController] startURLSchemeTask: %@", urlSchemeTask.request.URL);
  NSURL *url = [FileProxy serveLocalAsset:urlSchemeTask.request.URL.absoluteString];
  NSData *data = [NSData dataWithContentsOfURL:url];
  NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url MIMEType:@"*/*" expectedContentLength:-1 textEncodingName:nil];
  [urlSchemeTask didReceiveResponse:response];
  [urlSchemeTask didReceiveData:data];
  [urlSchemeTask didFinish];
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask { 
  NSLog(@"[ViewController] stopURLSchemeTask: %@", urlSchemeTask.request.URL);
  // cancel items here...
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
