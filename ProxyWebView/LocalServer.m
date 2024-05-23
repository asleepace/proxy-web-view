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
    
    _queue = dispatch_queue_create("local.server.queue", nil);
    
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
  
  //  nw_parameters_t parameters = nw_parameters_create();
    
  nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
  nw_parameters_t parameters;
  
  if (g_use_udp) {
      parameters = nw_parameters_create_secure_udp(
          configure_tls,
          NW_PARAMETERS_DEFAULT_CONFIGURATION
      );
  } else {
      parameters = nw_parameters_create_secure_tcp(
          configure_tls,
          NW_PARAMETERS_DEFAULT_CONFIGURATION
      );
  }
  
  nw_endpoint_t endpoint = nw_endpoint_create_host("0.0.0.0", "8888");
  //nw_parameters_set_local_only(parameters, true);
  nw_parameters_set_include_peer_to_peer(parameters, true);
  nw_parameters_set_reuse_local_address(parameters, true);
  nw_parameters_set_local_endpoint(parameters, endpoint);
  
  //  FAST OPEN
  //  https://stackoverflow.com/a/70122201/4326715
  nw_parameters_set_fast_open_enabled(parameters, true);
  
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
    }
  });
  
  nw_listener_set_new_connection_handler(self.listener, ^(nw_connection_t connection) {
    NSLog(@"[LocalServer] received new connection!");
    
    nw_connection_set_queue(connection, dispatch_get_main_queue());
    //nw_retain(connection);
    
    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
      NSLog(@"[LocalServer] connection handler state: %u error: %@", state, error);
      if (state == nw_connection_state_waiting) {
        NSLog(@"[LocalServer] tell the user that a connection couldn’t be opened but will retry when conditions are favourable");
      } else if (state == nw_connection_state_failed) {
        NSLog(@"[LocalServer] tell the user that the connection has failed irrecoverably");
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
  NSString *certPath = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"cer"];
  NSString *keyPath = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"p12"];
    
  NSData *certData = [NSData dataWithContentsOfFile:certPath];
  NSData *keyData = [NSData dataWithContentsOfFile:keyPath];
    
  if (!certData || !keyData) {
    NSLog(@"Failed to load certificate or private key");
    return NULL;
  }
    
  SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (CFDataRef)certData);
  if (!certificate) {
    NSLog(@"Failed to create certificate");
    return NULL;
  }
    
  CFArrayRef items = NULL;
  NSDictionary *options = @{(id)kSecImportExportPassphrase : @"your_password"}; // The password for the .p12 file
  OSStatus status = SecPKCS12Import((CFDataRef)keyData, (CFDictionaryRef)options, &items);
    
  if (status != errSecSuccess) {
      NSLog(@"Failed to import private key: %d", (int)status);
      return NULL;
  }
    
  NSArray *identities = (__bridge NSArray *)items;
  NSDictionary *identityDict = [identities objectAtIndex:0];
  SecIdentityRef identity = (SecIdentityRef)CFBridgingRetain([identityDict objectForKey:(id)kSecImportItemIdentity]);
    
  return identity;
}


@end
