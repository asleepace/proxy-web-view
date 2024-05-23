# proxy-web-view

Runs a local server which intercepts HTTP requests which can be preloaded to the webview.

![Simulator Screenshot - iPhone 15 - 2024-05-23 at 02 07 22](https://github.com/asleepace/proxy-web-view/assets/10716803/9987b4e0-ff9b-4663-9cbd-a245f00fb15e)

## How it works?

The application starts a local TCP server running at `http://0.0.0.0:8888` via the `LocalServer` class, which will try to match incoming requests with files found in the bundle. This works for loading a website via a local HTML file, or from a remote domain using `HTTP`.

## Limitations

Since the assets are serverd over `HTTP://` and not `HTTPS://` this will cause problems when mixing insecure content.

## Next Steps

The following approaches attempt to mitigate the mixed context issue.

1. Assets to be loaded locally use a custom scheme `my-app://` along with the `WKURLSchemeHandler`
2. Reuests are proxied via the `ProxyURLProtocol` which does a sort of MITM with content
3. Manage to locally sign the TCP server to serve secure content?
