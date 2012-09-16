//
//  TIXboxLiveEngineCookieBases.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 18/10/2011.
//  Copyright 2011 Tom Irving. All rights reserved.
//

@interface TIXboxLiveEngineCookieBase : NSObject {
	NSString * cookieHash;
	NSString * verificationToken;
}

@property (nonatomic, copy) NSString * cookieHash;
@property (nonatomic, copy) NSString * verificationToken;

@end