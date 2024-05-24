//
//  CertBot.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/23/24.
//

#import "CertBot.h"
#import <Security/Security.h>

@interface CertBot()

@end

@implementation CertBot

@synthesize host, port;

//  SHARED CLASS INSTANCE
//
+ (id)shared {
  static dispatch_once_t pred = 0;
  static id _sharedObject = nil;
  dispatch_once(&pred, ^{
    _sharedObject = [[self alloc] init];
  });
  return _sharedObject;
}

//  INITIALIZATION
//
- (id)init {
  if (self = [super init]) {
    self.host = @"0.0.0.0";
    self.port = @"8888";
  }
  return self;
}


#pragma mark - Bundled Resources


- (NSData *)getBundledCertificateData {
  NSString *certPath = [[NSBundle mainBundle] pathForResource:@"certificate" ofType:@"der"];
  NSData* certData = [NSData dataWithContentsOfFile:certPath];
  return certData;
}

- (NSData *)getBundledKey {
  NSString *keyPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"p12"];
  NSData *PKCS12Data = [NSData dataWithContentsOfFile:keyPath];
  return PKCS12Data;
}


#pragma mark - Self Signed



- (NSURL *)URLForServer {
  NSString *serverUrlString = [NSString stringWithFormat:@"https://%@:%@", host, port];
  NSURL *url = [NSURL URLWithString:serverUrlString];
  
  if (url != NULL) {
    NSLog(@"[CertBot] created url for server: %@", url.absoluteString);
  } else {
    NSLog(@"[CertBot] failed creating url for: %@", serverUrlString);
  }
  
  return url;
}



#pragma mark - Certificate



- (SecCertificateRef)getCertificate {
  NSData *pkcs12CertificateData = [self getBundledCertificateData];
  NSData *pkcs12PrivateKey = [self getBundledKey];

  if (!pkcs12CertificateData || !pkcs12PrivateKey) {
    NSLog(@"[CertBot] failed to load certificate or private key");
    return NULL;
  }
  
  SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorMalloc, (CFDataRef)pkcs12CertificateData);
  if (!certificate) {
    NSLog(@"[CertBot] failed creating certificate: %@", certificate);
    return NULL;
  }
  
  //  NOTE: This is the actual password for your certificate!!
  NSString *password = @"password";
  
  OSStatus securityError = errSecSuccess;
  const void *keys[] =   { kSecImportExportPassphrase };
  const void *values[] = { (__bridge CFStringRef)password };
  CFDictionaryRef optionsDictionary = NULL;
  optionsDictionary = CFDictionaryCreate(NULL, keys, values, (password?1:0), NULL, NULL);
  CFArrayRef items = NULL;

  //  IMPORT PKCS12
  securityError = SecPKCS12Import((__bridge CFDataRef)pkcs12PrivateKey, optionsDictionary, &items);
  
  if (securityError != errSecSuccess) {
    NSLog(@"[CertBot] invalid private key: %d", securityError);
    return NULL;
  }
  
  return certificate;
}

@end
