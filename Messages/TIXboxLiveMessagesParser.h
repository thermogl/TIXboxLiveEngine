//
//  TIXboxLiveMessageParser.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 24/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieBase.h"

typedef void (^TIXboxLiveMessagesParserMessagesBlock)(NSArray * messages);

@interface TIXboxLiveMessagesParser : TIXboxLiveEngineCookieBase
- (void)parseMessagesPage:(NSString *)aPage callback:(TIXboxLiveMessagesParserMessagesBlock)callback;
@end