//
//  TIXboxLiveEngineCookieBases.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 18/10/2011.
//  Copyright 2011 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieBase.h"

@implementation TIXboxLiveEngineCookieBase
@synthesize cookieHash;
@synthesize verificationToken;

- (void)dealloc {
	[cookieHash release];
	[verificationToken release];
	[super dealloc];
}

@end
