//
//  LocalServer.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//

#import "LocalServer.h"
#import <Network/Network.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

@interface LocalServer()

@property (nonatomic, strong) nw_listener_t listener;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (retain, nonatomic) nw_connection_t currentConnection;
@property (atomic) SecIdentityRef identity;

@property (nonatomic) uint16_t tlsEncryption;
@property (nonatomic) const char *dns;

@end

@implementation LocalServer

//  Convenience method for starting the local server
//  will initialize and create.
//
+ (LocalServer *)createLocalHTTPServer {
  return [[LocalServer alloc] init];
}

//  initialize the local server
//  start the connection.
//
- (id)init {
  if (self = [super init]) {
    
    self.queue = dispatch_queue_create("local.server.queue", nil);
    self.tlsEncryption = tls_ciphersuite_ECDHE_RSA_WITH_AES_128_GCM_SHA256; //Default encryption
    //self.tlsEncryption = tls_ciphersuite_RSA_WITH_AES_128_GCM_SHA256;
    self.dns = "http://0.0.0.0:8888";

    [self startServer];
  }
  return self;
}


//  We need to create a certificate (otherwise TLS won't work)
//  https://developer.apple.com/documentation/network/creating_an_identity_for_local_network_tls?language=objc
//
//  Also view Apple's code:
//  https://developer.apple.com/documentation/network/implementing_netcat_with_network_framework
//
- (void)startServer {
  
//  let tcpOption = NWProtocolTCP.Options()
//  tcpOption.enableKeepalive = true
//  tcpOption.keepaliveIdle = 2
  
  // nw_protocol_options_t protocol = nw_protocol_copy_tcp_definition();
  
  // nw_parameters_t parameters = nw_parameters_create_secure_tcp(NW_PARAMS, NW_PARAMETERS_DEFAULT_CONFIGURATION);
  // Create a listener
  
  // Toggle UDP/TCP
  bool g_use_udp = false;
  
//    nw_parameters_t parameters = nw_parameters_create();
    
  nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
  
//  nw_parameters_t parameters;
//  
//  if (g_use_udp) {
//      parameters = nw_parameters_create_secure_udp(
//          configure_tls,
//          NW_PARAMETERS_DEFAULT_CONFIGURATION
//      );
//  } else {
//      parameters = nw_parameters_create_secure_tcp(
//          configure_tls,
//          NW_PARAMETERS_DEFAULT_CONFIGURATION
//      );
//  }
  
  nw_parameters_t parameters = [self tls_params];
//  SecIdentityRef identity = [self createIdentity];
//  NSLog(@"[LocalServer] created identity: %@", identity);
  
//  nw_protocol_options_t options = nw_tls_create_options();
//  nw_parameters_t tlsParams = nw_parameters_create_quic(^(nw_protocol_options_t  _Nonnull options) {
//    
//    
//  });
  
//  // https://github.com/Apple-FOSS-Mirror/Security/blob/master/protocol/SecProtocolOptions.h
//
////  nw_parameters_t parameters = nw_parameters_create_secure_tcp(^(nw_protocol_options_t options) {
////    sec_protocol_options_t secOptions = nw_tls_copy_sec_protocol_options(options);
////    sec_protocol_options_set_local_identity(secOptions, CFBridgingRelease(identity));
////    NSLog(@"[LocalServer] set local identity!");
////  }, NW_PARAMETERS_DEFAULT_CONFIGURATION);
//  
//  //  START TLS
// //  nw_protocol_options_t tls = nw_tls_create_options();
//
//  nw_protocol_options_t tlsOptions = nw_tls_create_options();
//  sec_protocol_options_t secOptions = nw_tls_copy_sec_protocol_options(tlsOptions);
//  
//  // Set the local identity
//  sec_protocol_options_set_local_identity(secOptions, (__bridge sec_identity_t _Nonnull)(identity));
//  sec_protocol_options_set_challenge_block(secOptions, ^(sec_protocol_metadata_t  _Nonnull metadata, sec_protocol_challenge_complete_t  _Nonnull complete) {
//    NSLog(@"[LocalServer] challenge block %@", complete);
//    
//  }, dispatch_get_main_queue());
//  
//  sec_protocol_options_set_verify_block(secOptions,
//  ^(sec_protocol_metadata_t  _Nonnull metadata, sec_trust_t  _Nonnull trust_ref, sec_protocol_verify_complete_t  _Nonnull complete) {
//    NSLog(@"[LocalServer] verify block %@", complete);
//    
//  }, dispatch_get_main_queue());
//  // Create secure TCP parameters
//
//       
//  // Set other TLS options as needed
//  // For example, to disable certain versions of TLS:
//  // sec_protocol_options_add_tls_version(secOptions, tls_protocol_version_TLSv12);
//      
//  //  END TLS
  
  nw_endpoint_t endpoint = nw_endpoint_create_host("0.0.0.0", "8888");
  //nw_parameters_set_local_only(parameters, true);
  //nw_parameters_set_include_peer_to_peer(parameters, true);
  nw_parameters_set_reuse_local_address(parameters, true);
  nw_parameters_set_local_endpoint(parameters, endpoint);
  
  //  FAST OPEN
  //  https://stackoverflow.com/a/70122201/4326715
  //nw_parameters_set_fast_open_enabled(parameters, true);
  
  self.listener = nw_listener_create(parameters);
  nw_listener_set_queue(self.listener, self.queue);
  // nw_listener_set_queue(self.listener, dispatch_get_main_queue());

  // nw_parameters_set_required_interface_type(parameters, nw_interface_type)

  // Set the state change handler
  nw_listener_set_state_changed_handler(self.listener, ^(nw_listener_state_t state, nw_error_t error) {
    if (state == nw_listener_state_ready) {
      NSLog(@"[LocalServer] server is ready and listening on port 8888");
    } else if (state == nw_listener_state_failed) {
      NSLog(@"[LocalServer] server failed with error: %@", error);
    } else {
      NSLog(@"[LocalServer] state changed: %u (%@)", state, error);
    }
  });
  
  nw_listener_set_new_connection_handler(self.listener, ^(nw_connection_t connection) {
    NSLog(@"[LocalServer] received new connection!");
    
    nw_connection_set_queue(connection, dispatch_get_main_queue());
    
    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
      NSLog(@"[LocalServer] connection handler state: %u error: %@", state, error);
      
      if (state == nw_connection_state_waiting) {
        NSLog(@"[LocalServer] connection waiting...");
        
      } else if (state == nw_connection_state_preparing) {
        NSLog(@"[LocalServer] preparing connection!");
        
      } else if (state == nw_connection_state_invalid) {
        NSLog(@"[LocalServer] connection invalid!]");

      } else if (state == nw_connection_state_failed) {
        NSLog(@"[LocalServer] connection failed!");
        
      } else if (state == nw_connection_state_cancelled) {
        NSLog(@"[LocalServer] connection cancelled");
        // NOTE: we need to clear this connection
        //nw_release(connection);
      } else if (state == nw_connection_state_ready) {
        NSLog(@"[LocalServer] tell the user that you are connected");
        nw_connection_receive(connection, 1, UINT32_MAX,
            ^(dispatch_data_t content, nw_content_context_t context, bool is_complete, nw_error_t receive_error) {
          
          //  SERVER RESPONSE
          //  The following block handles sending data back to the client.
          NSLog(@"[LocalServer] received content: %@", content);
          NSLog(@"[LocalServer] received context: %@", context);
          NSData *data = (NSData *)content;
          NSString *dataString = [NSString stringWithUTF8String:[data bytes]];
          NSLog(@"[LocalServer] data string: %@", dataString);
          
          //  NSURL *url = [[NSBundle mainBundle] URLForResource:@"vault_boy" withExtension:@"jpeg"];
          //  NSData *image_data = [NSData dataWithContentsOfURL:url];
          NSData *file_data = [self loadResource:dataString];
          NSString *httpResponse = [NSString stringWithFormat:@"HTTP/1.1 200 OK\r\n"
                                    "Content-Type: */*\r\n"
                                    "Content-Length: %lu\r\n"
                                    "Connection: keep-alive\r\n"
                                    "\r\n", (unsigned long)file_data.length];
          
          NSMutableData *res = [NSMutableData data];
          [res appendData:[httpResponse dataUsingEncoding:NSUTF8StringEncoding]];
          [res appendData:file_data];
          
          NSLog(@"[LocalServer] response data: %ld", [res length]);
          
          dispatch_data_t response_data = dispatch_data_create(res.bytes, res.length, dispatch_get_main_queue(), DISPATCH_DATA_DESTRUCTOR_DEFAULT);

          nw_connection_send(connection, response_data, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, true, 
                             ^(nw_error_t res_error) {
            NSLog(@"[LocalServer] sent error: %@", res_error);
            nw_connection_cancel(connection);
          });
          
          NSLog(@"[LocalServer] connection receive: %@ error: %@", is_complete ? @"yes" : @"no", error);
        });
      }
    });
    
    nw_connection_start(connection);
  });
  

  // start the listener
  nw_listener_start(self.listener);
}


- (NSData *)loadResource:(NSString *)headers {
  
  NSRange getRange = [headers rangeOfString:@"GET /"];
  if (getRange.location != NSNotFound) {
    NSRange httpRange = [headers rangeOfString:@" HTTP/1.1"];
    if (httpRange.location != NSNotFound) {
      NSUInteger pathStart = NSMaxRange(getRange);
      NSUInteger pathLength = httpRange.location - pathStart;
      NSRange pathRange = NSMakeRange(pathStart, pathLength);
      NSString *path = [headers substringWithRange:pathRange];
      NSLog(@"[LocalServer] extracted path: %@", path);
      
      NSArray *info = [path componentsSeparatedByString:@"."];
      NSString *fileName = [info objectAtIndex:0];
      NSString *extension = [info objectAtIndex:1];
      
      NSLog(@"[LocalServer] filename: \"%@\" extension: \"%@\"", fileName, extension);
      
      NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:extension];
      NSData *data = [NSData dataWithContentsOfURL:url];
      return data;
      
    } else {
      NSLog(@"[LocalServer] HTTP version not found in request");
    }
  } else {
      NSLog(@"GET method not found in request");
  }
  
  return [NSData data];
}



#pragma mark - TLS Security

- (void)tlsCertificate {
  
  SecIdentityRef identity = [self createIdentity];
  if (identity == NULL) {
      NSLog(@"Failed to create identity");
      return;
  }
  
  nw_protocol_options_t tlsOptions = nw_tls_create_options();
  sec_protocol_options_t secOptions = nw_tls_copy_sec_protocol_options(tlsOptions);
  sec_protocol_options_set_local_identity(secOptions, CFBridgingRelease(identity));
}


- (SecIdentityRef)createIdentity {
  // Load the certificate and private key from the app bundle
  NSString *certPath = [[NSBundle mainBundle] pathForResource:@"certificate" ofType:@"der"];
  NSString *keyPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"p12"];
    
  NSData *certData = [NSData dataWithContentsOfFile:certPath];
  NSData *PKCS12Data = [NSData dataWithContentsOfFile:keyPath];
    
  if (!certData || !PKCS12Data) {
    NSLog(@"[LocalServer] failed to load certificate or private key");
    return NULL;
  }
  
    
  SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorMalloc, (CFDataRef)certData);
  if (!certificate) {
    NSLog(@"[LocalServer] Failed to create certificate!!!!");
    return NULL;
  }
  
  NSString *password = @"password";
  OSStatus securityError = errSecSuccess;

  const void *keys[] =   { kSecImportExportPassphrase };
  const void *values[] = { (__bridge CFStringRef)password };
  CFDictionaryRef optionsDictionary = NULL;

  optionsDictionary = CFDictionaryCreate(
                                         NULL, keys,
                                         values, (password?1:0),
                                         NULL, NULL);
  CFArrayRef items = NULL;

  securityError = SecPKCS12Import((__bridge CFDataRef)PKCS12Data,
                                  optionsDictionary,
                                  &items);
  
  if (securityError != errSecSuccess) {
    NSLog(@"[LocalServer] Failed to import private key: %d", securityError);
    return NULL;
  }
    
//  CFArrayRef items = NULL;
//  NSDictionary *options = @{(id)kSecImportExportPassphrase : @"password"}; // The password for the .p12 file
//  OSStatus status = SecPKCS12Import((CFDataRef)keyData, (CFDictionaryRef)options, &items);
//    
//  if (status != errSecSuccess) {
//      NSLog(@"[LocalServer] Failed to import private key: %d", (int)status);
//      return NULL;
//  }
    
  NSArray *identities = (__bridge NSArray *)items;
  NSDictionary *identityDict = [identities objectAtIndex:0];
  self.identity = (SecIdentityRef)CFBridgingRetain([identityDict objectForKey:(id)kSecImportItemIdentity]);
  NSLog(@"[LocalServer] identity: %@", self.identity);
  
  return self.identity;
}



//  Create NW Parameters with TLS
//  https://github.com/eamonwhiter73/IOSObjCWebSockets/blob/7836b0d4ccaf2744c069a32f715b63ead8103905/IOSObjCWebSockets/IOSObjCWebSockets.m#L72
//
- (nw_parameters_t)tls_params {
  nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DEFAULT_CONFIGURATION;
  
  //Create TLS protocol, this part might end up needing to be reconfigured given the intent of your app.
  configure_tls = ^(nw_protocol_options_t tls_options) {
    NSLog(@"[LocalServer] configure tls...");
    sec_protocol_options_t sec_options = nw_tls_copy_sec_protocol_options(tls_options);
      
    //VERY IMPORTANT OPTIONS
    sec_protocol_options_append_tls_ciphersuite(sec_options, self.tlsEncryption); //may need to change based on the encryption you are using
    
    sec_protocol_options_set_min_tls_protocol_version(sec_options, tls_protocol_version_TLSv12); //below TLSv1 is defnitely not advisable
    // should pin to TLSv12
    // https://forums.developer.apple.com/forums/thread/118035
    sec_protocol_options_set_max_tls_protocol_version(sec_options, tls_protocol_version_TLSv12); //set max TLS version to TLSv1.3 (you will probably be using TLSv1.2)
    if(self.dns != NULL) {
      sec_protocol_options_set_tls_server_name(sec_options, self.dns); //VERY IMPORTANT, needed for connection to work. Must be the same as the DNS name that you are using for your server. See this for a great guide for how to create certificates that work with TLS and iOS -> https://jamielinux.com/docs/openssl-certificate-authority/introduction.html
    } else {
      NSLog(@"***IMPORTANT*** YOU NEED TO SET THE DNS ***IMPORTANT***");
    }
    
    SecIdentityRef identity = [self createIdentity];
    
    sec_identity_t ident = (__bridge sec_identity_t _Nonnull)(identity);
    
    if (ident != NULL) {
      NSLog(@"[TLS] setting local identity!");
      sec_protocol_options_set_local_identity(sec_options, ident);
    } else {
      NSLog(@"[TLS] identity is null!");
    }

    
    
    //  HANDSHAKE VERIFY BLOCK
    //  This block performs the verification step.
    //
    sec_protocol_options_set_verify_block(sec_options, ^(sec_protocol_metadata_t  _Nonnull metadata, sec_trust_t  _Nonnull trust_ref, sec_protocol_verify_complete_t  _Nonnull complete) {
        
      NSLog(@"[Handshake] verify block: %@", complete ? @"complete" : @"ongoing");
      NSLog(@"[Handshake] metadata: %@", metadata);
        
      SecTrustRef trust = sec_trust_copy_ref(trust_ref);
      SecCertificateRef ref = SecTrustGetCertificateAtIndex(trust, 0); //get certificate from connection at index

        
        CFMutableArrayRef cert_arr = CFArrayCreateMutable(NULL, 1, &kCFTypeArrayCallBacks);
        CFArrayAppendValue(cert_arr, ref);
          
          //Maybe not neccessary - but won't hurt, setting the correct cerificate (verfiably) as an anchor certificate.
        OSStatus set = SecTrustSetAnchorCertificates(trust, cert_arr);
          
          //LEAVE FOR DEBUGGING YOUR CONNECTION! VERIFY TLS RELATED VERSIONS. TAKE OUT FOR PRODUCTION.
          //***************************************************************************************
          const char* server_name = sec_protocol_metadata_get_server_name(metadata);
          tls_protocol_version_t proto_v = sec_protocol_metadata_get_negotiated_tls_protocol_version(metadata);
          tls_ciphersuite_t suite = sec_protocol_metadata_get_negotiated_tls_ciphersuite(metadata);
          
          NSLog(@"[Handshake] server name: %s", server_name);
          NSLog(@"[Handshake] protocol version: %hu", proto_v);
          NSLog(@"[Handshake] protocol ciphersuite: %hu", suite);
          NSLog(@"[Handshake] certifcate count: %ld",(long)SecTrustGetCertificateCount(trust));
          NSLog(@"[Handshake] error setting certificate as anchor: %@", SecCopyErrorMessageString(set, NULL));
          //***************************************************************************************
          
          OSStatus status = SecTrustEvaluateAsyncWithError(trust, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^(SecTrustRef  _Nonnull trustRef, bool result, CFErrorRef  _Nullable error) {
              if(error) {
                  //LEAVE FOR DEBUGGING YOUR CONNECTION! VERIFY TLS RELATED VERSIONS. TAKE OUT FOR PRODUCTION.
                  //***************************************************************************************
                  NSLog(@"error code with trust evaluation: %li", (long)CFErrorGetCode(error));
                  NSLog(@"error domain with trust evaluation: %@", CFErrorGetDomain(error));
                  NSLog(@"error with trust evaluation - not human readable: %@", error);
                  NSLog(@"error with trust evaluation - human readable: %@", CFErrorCopyDescription(error));
                  NSLog(@"result in error block for trust evaluation: %i", result);
                  //***************************************************************************************
                  
                  complete(false);
              }
              else {
                  NSLog(@"positive result for trust evaluation: %i", result);
                  complete(result);
              }
          });
          
          //LEAVE FOR DEBUGGING YOUR CONNECTION! VERIFY TLS RELATED VERSIONS. TAKE OUT FOR PRODUCTION.
          //***************************************************************************************
          NSLog(@"status of trust evaluation - human readable: %@", SecCopyErrorMessageString(status, NULL));
          //***************************************************************************************
          
      }, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)); //I handle it async on the background queue because this has to happen everytime a connection is created, which happens everytime you send data!
  };
  
  //Can use the below line to ignore having to configure tls (everything above is rendered mute by NW_PARAMETERS_DISABLE_PROTOCOL)
  //nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
  nw_parameters_t parameters = nw_parameters_create_secure_tcp(
      configure_tls,
      NW_PARAMETERS_DEFAULT_CONFIGURATION
  );
  
  return parameters;
}

@end
