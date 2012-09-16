//
//  TIXboxLiveGamesParser.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

typedef void (^TIXboxLiveGamesParserGamesBlock)(NSArray * games);

@interface TIXboxLiveGamesParser : NSObject
- (void)parseGamesPage:(NSString *)aPage callback:(TIXboxLiveGamesParserGamesBlock)callback;
- (void)parseGameComparisonsPage:(NSString *)aPage callback:(TIXboxLiveGamesParserGamesBlock)callback;
@end