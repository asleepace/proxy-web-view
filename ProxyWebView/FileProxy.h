//
//  FileProxy.h
//  ProxyWebView
//
//  Created by Colin Teahan on 5/25/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileProxy : NSObject

+ (NSURL *)serveLocalAsset:(NSString *)originalURL;

@end

NS_ASSUME_NONNULL_END
