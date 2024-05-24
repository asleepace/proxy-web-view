# proxy-web-view

Runs a local server which intercepts HTTP requests which can be preloaded to the webview.

### UPDATE: Now supports TLS*

Running the local server with a `https://0.0.0.0:8888` connnection works*, but results may vary depending on how the certificates actually work.


|Local HTML|Remote HTTP|
|----------|-----------|
|![Simulator Screenshot - iPhone 15 - 2024-05-23 at 02 07 22](https://github.com/asleepace/proxy-web-view/assets/10716803/9987b4e0-ff9b-4663-9cbd-a245f00fb15e)|![Simulator Screenshot - iPhone 15 - 2024-05-23 at 02 07 22](https://github.com/asleepace/proxy-web-view/assets/10716803/9987b4e0-ff9b-4663-9cbd-a245f00fb15e)|

## How it works?

The application starts a local TCP server running at `http://0.0.0.0:8888` via the `LocalServer` class, which will try to match incoming requests with files found in the bundle. This works for loading a website via a local HTML file, or from a remote domain using `HTTP`.

Much of the code was obtained from this article:

- https://developer.apple.com/documentation/network/implementing_netcat_with_network_framework

## Limitations

Since the assets are serverd over `HTTP://` and not `HTTPS://` this will cause problems when mixing insecure content.

## Next Steps

The following approaches attempt to mitigate the mixed context issue.

1. Assets to be loaded locally use a custom scheme `my-app://` along with the `WKURLSchemeHandler`
2. Reuests are proxied via the `ProxyURLProtocol` which does a sort of MITM with content
3. Manage to locally sign the TCP server to serve secure content?

## Testing

You can use the following two links to text a file which contains assets with `http://0.0.0.0:8888` link

- test http:  http://d.dlabs.me/test/example.html
- test https:  https://d.dlabs.me/test/example.html

## Generating SSL Certificates

```bash
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 3650 -keyout my.key -out my.cer;
```

Then we need to convert this to a `.der` file:

```bash
openssl x509 -in certificate.crt -outform der -out certificate.der
```

To generate the proper SSL certificates for the server, you can use the following commands:

```bash
openssl pkcs12 -legacy -export -out client.p12 -inkey my.key -in certificate.der
```

## Related Links

- [Setting up Netcat](https://developer.apple.com/documentation/network/implementing_netcat_with_network_framework)
- [Networking Proxy Config](https://developer.apple.com/documentation/network/nw_proxy_config_t?language=objc)
- [WKDataStore Proxy Configurations](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/4245799-proxyconfigurations?language=objc)
- [TLS Configuration (low level)](https://forums.developer.apple.com/forums/thread/755795)
- [Cocoa HTTP Server](https://github.com/robbiehanson/CocoaHTTPServer/blob/master/Core/HTTPServer.m)
- [Apple Questions: TLS Stuff (Quinn the Eskimo)](https://forums.developer.apple.com/forums/thread/739400)
- [Creating an identity for a local network](https://developer.apple.com/documentation/network/creating_an_identity_for_local_network_tls?language=objc)
- [How to use NWParameters TLS](https://forums.developer.apple.com/forums/thread/711114)
- [Apple Developer: Problems setting up local server](https://developer.apple.com/forums/thread/653925)
- [How to use MIME type](https://stackoverflow.com/questions/1363813/how-can-you-read-a-files-mime-type-in-objective-c)
- [Custom fonts in WKWebView](https://stackoverflow.com/questions/25785179/using-custom-fonts-in-wkwebview)
