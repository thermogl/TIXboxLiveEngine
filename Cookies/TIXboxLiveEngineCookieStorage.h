//
//  TIXboxLiveEngineCookieStorage.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/09/2011.
//  Copyright 2011 Tom Irving. All rights reserved.
//

typedef void (^TIXboxLiveEngineCookieBlock)(NSHTTPCookie * cookie);
@interface TIXboxLiveEngineCookieStorage : NSObject {
	NSString * cookieRootDirectory;
}

@property (nonatomic, copy) NSString * cookieRootDirectory;

+ (TIXboxLiveEngineCookieStorage *)sharedCookieStorage;

- (void)addCookiesFromResponse:(NSURLResponse *)response hash:(NSString *)cookieHash;
- (void)addCookies:(NSArray *)newCookies hash:(NSString *)cookieHash;
- (void)removeAllCookiesForHash:(NSString *)cookieHash;

- (NSArray *)cookiesForURL:(NSURL *)URL hash:(NSString *)cookieHash;
- (void)enumerateCookiesForURL:(NSURL *)URL hash:(NSString *)cookieHash block:(TIXboxLiveEngineCookieBlock)block;

@end