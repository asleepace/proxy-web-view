# proxy-web-view

Runs a local server which intercepts HTTP requests which can be preloaded to the webview.

## How it works?

The application starts a local TCP server running at `http://0.0.0.0:8888` via the `LocalServer` class, which will try to match incoming requests with files found in the bundle. This works for loading a website via a local HTML file, or from a remote domain using `HTTP`.

## Limitations

Since the assets are serverd over `HTTP://` and not `HTTPS://` this will cause problems when mixing insecure content.

## Next Steps

The following approaches attempt to mitigate the mixed context issue.

1. Assets to be loaded locally use a custom scheme `my-app://` along with the `WKURLSchemeHandler`
2. Reuests are proxied via the `ProxyURLProtocol` which does a sort of MITM with content
3. Manage to locally sign the TCP server to serve secure content?
