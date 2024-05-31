//
//  FileProxy.m
//  ProxyWebView
//
//  Created by Colin Teahan on 5/25/24.
//

#import "FileProxy.h"

@implementation FileProxy

+ (NSURL *)serveLocalAsset:(NSString *)originalURL {
  NSString *file = [originalURL lastPathComponent];
  NSLog(@"[FileProxy] looking for %@", file);
  
  NSArray<NSString *> *components = [file componentsSeparatedByString:@"."];
  NSString *fileName = [components objectAtIndex:0];
  NSString *filePath = [components objectAtIndex:1];
  
  NSLog(@"[FileProxy] name: %@ path: %@", fileName, filePath);
  
  NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:filePath];
//  NSData *data = [NSData dataWithContentsOfURL:url];
//  return data;
  return url;
}



+ (NSData *)serveRequestData:(NSString *)headers {
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

  return [NSData data]; // empty data
}

@end
