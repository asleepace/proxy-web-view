//
//  HTML.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/25/24.
//

#import "HTML.h"

@implementation HTML

+ (NSString *)generate {
  NSString *htmlString = [NSString stringWithFormat:
                        @"<html>\n"
                         "  <head>\n"
                         "    <title>Dynamic Fonts</title>\n"
                         "    <meta charset=\"utf-8\">\n"
                         "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
                         "    <style>\n"
                         "      @font-face {\n"
                         "        font-family: 'Immaterial';\n"
                         "        src: url('https://0.0.0.0:8888/Immaterial.ttf');\n"
                         "      }\n"
                         "      @font-face {\n"
                         "        font-family: 'Lobster-Regular';\n"
                         "        src: url('https://0.0.0.0:8888/Lobster-Regular.ttf');\n"
                         "      }\n"
                         "      html,\n"
                         "      body {\n"
                         "        font-family: 'Lobster-Regular', sans-serif;\n"
                         "        background-color: lightskyblue;\n"
                         "        margin: auto 0;\n"
                         "        min-height: 100vh;\n"
                         "        width: 100vw;\n"
                         "      }\n"
                         "      h1 {\n"
                         "        text-align: center;\n"
                         "        font-size: 3rem;\n"
                         "      }\n"
                         "      .container {\n"
                         "        display: flex;\n"
                         "        flex-direction: column;\n"
                         "        flex: 1;\n"
                         "      }\n"
                         "      .blurb {\n"
                         "        background-color: rgba(0, 0, 0, 0.9);\n"
                         "        border-radius: 16px;\n"
                         "        padding: 4px 16px;\n"
                         "        margin: 8px 8px;\n"
                         "      }\n"
                         "      p {\n"
                         "        color: rgba(255, 255, 255, 0.9);\n"
                         "        font-family: sans-serif;\n"
                         "        line-height: 24px;\n"
                         "        font-weight: 500;\n"
                         "        font-size: 18px;\n"
                         "      }\n"
                         "      a {\n"
                         "        color: white;\n"
                         "        font-family: monospace;\n"
                         "        text-decoration: none;\n"
                         "        font-weight: 700;\n"
                         "      }\n"
                         "    </style>\n"
                         "  </head>\n"
                         "  <body>\n"
                         "    <div class=\"container\">\n"
                         "      <h1>Dynamic Fonts</h1>\n"
                         "      <img src=\"https://0.0.0.0:8888/vault_boy.jpeg\" alt=\"Vault\" width=\"100%%\" style=\"aspect-ratio: calc(16/9);\" />\n"
                         "      <div class=\"blurb\">\n"
                         "      <p>The assets on this page are served by a local server running on the same device at <a href=\"https://0.0.0.0:8888\">https://0.0.0.0:8888</a> which provides both the image and font dynamically on the page.</p>\n"
                         "      </div>\n"
                         "    </div>\n"
                         "  </body>\n"
                         "</html>"];
  
  NSString *endpoint = [NSString stringWithCString:Config.HTTPS_ENDPOINT encoding:NSUTF8StringEncoding];
  NSString *output = [htmlString stringByReplacingOccurrencesOfString:@"https://0.0.0.0:8888" withString:endpoint];
  return [HTML writeToDisk:output];
}


+ (NSString *)writeToDisk:(NSString *)htmlString {
  // Get the path to the Documents directory
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths firstObject];

  // Create the full file path
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"index.html"];

  // Write the HTML string to the file
  NSError *error;
  BOOL success = [htmlString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

  if (success) {
      NSLog(@"[HTML] File successfully written to %@", filePath);
  } else {
      NSLog(@"[HTML] Error writing file: %@", [error localizedDescription]);
  }
  
  return filePath;
}


@end
