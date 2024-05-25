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

static NSString *SERVER_HOST = @"local-server";
static NSString *SERVER_PORT = @"8888";

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



#pragma mark - AddToKeychain


- (void)addToKeychain:(CFArrayRef)items {
  NSArray *identities = (__bridge NSArray *)items;
  NSDictionary *identityDict = [identities objectAtIndex:0];
  NSLog(@"[CertBot] identityDict: %@", identityDict);
    
  SecIdentityRef identity = (SecIdentityRef)CFBridgingRetain([identityDict objectForKey:(id)kSecImportItemIdentity]);
  NSLog(@"[CertBot] identity: %@", identity);
  
  NSDictionary *dict = @{
    (NSString *)kSecValueRef: [identityDict objectForKey:(NSString *)kSecImportItemIdentity],
    (NSString *)kSecAttrLabel: @"ListenerIdentityLabel",
  };
  
  CFDictionaryRef ref = CFBridgingRetain(dict);
  OSStatus status = SecItemAdd(ref, nil);
  
  if (status == errSecSuccess) {
    NSLog(@"[CertBot] added item!");
  } else {
    NSLog(@"[CertBot] failed adding item: %d", (int)status);
  }
  
  // get sec from keychain
  // https://developer.apple.com/documentation/network/creating_an_identity_for_local_network_tls?changes=_6&language=objc
  NSDictionary* query_ref = @{
    (NSString *)kSecClass: (NSString *)kSecClassCertificate,
    (NSString *)kSecAttrLabel: @"ListenerIdentityLabel",
    (NSString *)kSecReturnRef: @1
  };
  
  SecItemCopyMatching(CFBridgingRetain(query_ref), nil);
  CFTypeRef item = NULL;
  CFDictionaryRef query_dict_ref = CFBridgingRetain(query_ref);
  OSStatus copy_status = SecItemCopyMatching(query_dict_ref, &item);
  
  NSLog(@"[CertBot] copy status: %d", copy_status);
  
  // in memory trick for writing
  // https://stackoverflow.com/questions/45997841/how-to-get-a-secidentityref-from-a-seccertificateref-and-a-seckeyref
  if (item != NULL) {
    
    CFMutableArrayRef cert_arr = CFArrayCreateMutable(NULL, 1, &kCFTypeArrayCallBacks);
    CFArrayAppendValue(cert_arr, item);
    
    SecIdentityRef copied_cert_ref = NULL;
    sec_identity_t identity_with_cert = sec_identity_create_with_certificates(copied_cert_ref, cert_arr);
    
    if (copied_cert_ref != NULL) NSLog(@"[TLS] copied cert ref!");
    if (identity_with_cert != NULL) NSLog(@"[TLS] copied identity ref!");

    NSLog(@"[CertBot] found security item: %@", item);
  } else {
    NSLog(@"[CertBot] could not find security item!");
  }
  
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
  
  //  OPTIONAL
  [self addToKeychain:items];
  
  return certificate;
}

@end
