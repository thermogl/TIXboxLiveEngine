//
//  TIXboxLiveEngineCookieStorage.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/09/2011.
//  Copyright 2011 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieStorage.h"
#import "TIXboxLiveEngineAdditions.h"

@interface TIXboxLiveEngineCookieStorage (Private)
- (NSString *)filePathForHash:(NSString *)hash;
@end

@implementation TIXboxLiveEngineCookieStorage
@synthesize cookieRootDirectory = _cookieRootDirectory;

- (void)addCookiesFromResponse:(NSURLResponse *)response hash:(NSString *)cookieHash {
	
	if ([response isKindOfClass:[NSHTTPURLResponse class]]){
		NSDictionary * headers = [(NSHTTPURLResponse *)response allHeaderFields];
		[self addCookies:[NSHTTPCookie cookiesWithResponseHeaderFields:headers forURL:response.URL] hash:cookieHash];
	}
}

- (void)addCookies:(NSArray *)newCookies hash:(NSString *)cookieHash {
	
	if (newCookies && cookieHash){
		
		NSMutableArray * allCookies = [NSMutableArray arrayWithContentsOfFile:[self filePathForHash:cookieHash]];
		if (!allCookies) allCookies = [NSMutableArray array];
		
		[newCookies enumerateObjectsUsingBlock:^(NSHTTPCookie * newCookie, NSUInteger idx, BOOL *stop){

			if (![newCookie.name isEqualToString:@"MSPRequ"]){
				[allCookies enumerateObjectsUsingBlock:^(NSDictionary * existingCookieProperties, NSUInteger idx, BOOL * secondStop){
				
					NSHTTPCookie * existingCookie = [NSHTTPCookie cookieWithProperties:existingCookieProperties];
				
					BOOL cookiesEqual = [existingCookie.name isEqualToString:newCookie.name] &&
					[existingCookie.domain isEqualToString:newCookie.domain] && [existingCookie.path isEqualToString:newCookie.path];
				
					if (cookiesEqual){
						[allCookies removeObject:existingCookieProperties];
						*secondStop = YES;
					}
				}];
				
				[allCookies addObject:newCookie.properties];
			}
		}];
		
		[allCookies writeToFile:[self filePathForHash:cookieHash] atomically:YES];
	}
}

- (void)removeAllCookiesForHash:(NSString *)cookieHash {
	if (cookieHash) [[NSFileManager defaultManager] removeItemAtPath:[self filePathForHash:cookieHash] error:NULL];
}

- (NSArray *)cookiesForURL:(NSURL *)URL hash:(NSString *)cookieHash {
	
	NSMutableArray * validCookies = [NSMutableArray array];
	[self enumerateCookiesForURL:URL hash:cookieHash block:^(NSHTTPCookie * cookie){[validCookies addObject:cookie];}];
	return validCookies;
}

- (void)enumerateCookiesForURL:(NSURL *)URL hash:(NSString *)cookieHash block:(TIXboxLiveEngineCookieBlock)block {
	
	if (URL.host && cookieHash && block){
		
		NSMutableArray * allCookies = [NSMutableArray arrayWithContentsOfFile:[self filePathForHash:cookieHash]];
		__block BOOL removedExpiredCookie = NO;
		
		[allCookies enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * cookieProperties, NSUInteger idx, BOOL *stop){
			NSHTTPCookie * cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
			
			BOOL hasExpired = ([cookie.expiresDate timeIntervalSinceNow] < 0);
			if (!hasExpired){
				
				BOOL matchesHost = ([cookie.domain isEqualToString:URL.host] ||
									([cookie.domain hasPrefix:@"."] && [[@"." stringByAppendingString:URL.host] hasSuffix:cookie.domain]));
				
				BOOL matchesPath = ([URL.path hasPrefix:cookie.path]);
				if (matchesHost && matchesPath) block(cookie);
			}
			else
			{
				[allCookies removeObject:cookieProperties];
				removedExpiredCookie = YES;
			}
		}];
		
		if (removedExpiredCookie) [allCookies writeToFile:[self filePathForHash:cookieHash] atomically:YES];
	}
}

- (NSString *)filePathForHash:(NSString *)hash {
	return [_cookieRootDirectory stringByAppendingFormat:@"%@.cookies", hash];
}

#pragma mark - Singleton stuff
+ (TIXboxLiveEngineCookieStorage *)sharedCookieStorage {
	
	static TIXboxLiveEngineCookieStorage * shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{shared = [[self alloc] init];});
	
	return shared;
}

@end