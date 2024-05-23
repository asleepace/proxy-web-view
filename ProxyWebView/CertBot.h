//
//  CertBot.h
//  ProxyWebView
//
//  Created by Colin Teahan on 5/23/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CertBot : NSObject

@property (strong, nonatomic) NSString *host;
@property (strong, nonatomic) NSString *port;

+ (CertBot *)shared;
- (SecCertificateRef)getCertificate;

@end

NS_ASSUME_NONNULL_END
