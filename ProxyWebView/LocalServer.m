//
//  LocalServer.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/22/24.
//

#import "LocalServer.h"
#import <Network/Network.h>

@interface LocalServer()

@property (nonatomic, strong) nw_listener_t listener;

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
  
  self.listener = nw_listener_create(parameters);
  nw_listener_set_queue(self.listener, dispatch_get_main_queue());

  // nw_parameters_set_required_interface_type(parameters, nw_interface_type)

  // Set the state change handler
  nw_listener_set_state_changed_handler(self.listener, ^(nw_listener_state_t state, nw_error_t error) {
    if (state == nw_listener_state_ready) {
      NSLog(@"[LocalServer] server is ready and listening on port 8888");
    } else if (state == nw_listener_state_failed) {
      NSLog(@"[LocalServer] server failed with error: %@", error);
    }
  });

  // Set the new connection handler
  nw_listener_set_new_connection_handler(self.listener, ^(nw_connection_t connection) {
    [self handleNewConnection:connection];
  });

  // Start the listener
  nw_listener_start(self.listener);
}

- (void)handleNewConnection:(nw_connection_t)connection {
  NSLog(@"[LocalServer] handle new connection: %@", connection.description);
  // Set the state change handler for the connection
  nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
    if (state == nw_connection_state_ready) {
      NSLog(@"[LocalServer] accepted new connection");
      [self receiveRequestOnConnection:connection];
    } else if (state == nw_connection_state_failed) {
      NSLog(@"[LocalServer] connection failed with error: %@", error);
    }
  });

  // Start the connection
  nw_connection_start(connection);
}

- (void)receiveRequestOnConnection:(nw_connection_t)connection {
  // Set the receive handler
  nw_connection_receive_message(connection, ^(dispatch_data_t content, nw_content_context_t context, bool is_complete, nw_error_t receive_error) {
      if (content) {
          NSString *request = [[NSString alloc] initWithData:(NSData *)content encoding:NSUTF8StringEncoding];
          NSLog(@"[LocalServer] received request: %@", request);

          // Prepare a simple HTTP response
          NSString *response = @"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello from the local HTTP server!";
          NSData *responseData = [response dataUsingEncoding:NSUTF8StringEncoding];

          // Send the response
          dispatch_data_t responseDispatchData = dispatch_data_create((const void *)[responseData bytes], [responseData length], dispatch_get_main_queue(), ^{
              // No cleanup needed
          });

          nw_connection_send(connection, responseDispatchData, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, true, ^(nw_error_t send_error) {
              if (send_error) {
                  NSLog(@"Failed to send response with error: %@", send_error);
              } else {
                  NSLog(@"Response sent successfully");
              }

              // Close the connection
              nw_connection_cancel(connection);
          });
      } else if (receive_error) {
          NSLog(@"Failed to receive data with error: %@", receive_error);
      }
  });
}

@end
