//
//  TIXboxLiveGamesParser.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveGamesParser.h"
#import "TIXboxLiveGame.h"
#import "TIXboxLiveEngineAdditions.h"

@implementation TIXboxLiveGamesParser

- (void)parseGamesPage:(NSString *)aPage callback:(TIXboxLiveGamesParserGamesBlock)callback {
	
	dispatch_async_serial("com.TIXboxLiveEngine.GamesParseQueue", ^{
		
		NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
		NSMutableArray * games = [NSMutableArray array];
		
		NSDictionary * gamesData = [(NSDictionary *)[aPage objectFromJSONString] safeObjectForKey:@"Data"];
		NSArray * rawGames = [gamesData safeObjectForKey:@"Games"];
		[rawGames enumerateObjectsUsingBlock:^(NSDictionary * rawGame, NSUInteger idx, BOOL *stop){
			
			NSDictionary * progressDict = (NSDictionary *)[rawGame safeObjectForKey:@"Progress"];
			NSDictionary * playerDict = [progressDict safeObjectForKey:[gamesData safeObjectForKey:@"CurrentGamertag"]];
			NSString * possibleAchievements = [rawGame safeObjectForKey:@"PossibleAchievements"];
			
			if (possibleAchievements.intValue > 0){
				
				NSURL * tileURL = [NSURL URLWithString:[rawGame safeObjectForKey:@"BoxArt"]];
				NSDate * lastPlayedDate = [[playerDict safeObjectForKey:@"LastPlayed"] dateFromJSONDate];
				
				TIXboxLiveGame * game = [[TIXboxLiveGame alloc] initWithTitle:[rawGame safeObjectForKey:@"Name"] 
																	  titleID:[[rawGame safeObjectForKey:@"Id"] stringValue]
															   lastPlayedDate:lastPlayedDate
																	  tileURL:tileURL];
				[game setUnlockedScore:[[playerDict safeObjectForKey:@"Score"] integerValue]];
				[game setTotalScore:[[rawGame safeObjectForKey:@"PossibleScore"] integerValue]];
				[game setUnlockedAchievements:[[playerDict safeObjectForKey:@"Achievements"] integerValue]];
				[game setTotalAchievements:[possibleAchievements integerValue]];
				[game setRelativeDateStamp:[lastPlayedDate relativeDateStringWithDateFormatter:dateFormatter]];
				[games addObject:game];
			}
		}];
		
		dispatch_async_main_queue(^{callback(games);});
	});
}

- (void)parseGameComparisonsPage:(NSString *)aPage callback:(TIXboxLiveGamesParserGamesBlock)callback {
	
	dispatch_async_serial("com.TIXboxLiveEngine.GameComparisonParseQueue", ^{
		
		NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
		NSMutableArray * games = [NSMutableArray array];
		
		NSDictionary * gamesData = [(NSDictionary *)[aPage objectFromJSONString] safeObjectForKey:@"Data"];
		NSArray * rawGames = [gamesData safeObjectForKey:@"Games"];
		[rawGames enumerateObjectsUsingBlock:^(NSDictionary * rawGame, NSUInteger idx, BOOL *stop){
			
			NSDictionary * progressDict = (NSDictionary *)[rawGame safeObjectForKey:@"Progress"];		
			__block NSString * comparedGamertag = nil;
			
			[progressDict.allKeys enumerateObjectsUsingBlock:^(NSString * key, NSUInteger idx, BOOL *stop){
				if (![key isEqualToString:[gamesData safeObjectForKey:@"CurrentGamertag"]]){
					comparedGamertag = key;
					*stop = YES;
				}
			}];
			
			NSDictionary * comparedPlayerDict = [progressDict safeObjectForKey:comparedGamertag];
			NSString * possibleAchievements = [rawGame safeObjectForKey:@"PossibleAchievements"];
			
			NSDate * lastPlayedDate = [[comparedPlayerDict safeObjectForKey:@"LastPlayed"] dateFromJSONDate];
			
			if (possibleAchievements.intValue > 0 && lastPlayedDate){
				
				NSURL * tileURL = [NSURL URLWithString:[rawGame safeObjectForKey:@"BoxArt"]];
				
				TIXboxLiveGame * game = [[TIXboxLiveGame alloc] initWithTitle:[rawGame safeObjectForKey:@"Name"] 
																	  titleID:[rawGame safeObjectForKey:@"Id"] 
															   lastPlayedDate:lastPlayedDate
																	  tileURL:tileURL];
				[game setUnlockedScore:[[comparedPlayerDict safeObjectForKey:@"Score"] integerValue]];
				[game setTotalScore:[[rawGame safeObjectForKey:@"PossibleScore"] integerValue]];
				[game setUnlockedAchievements:[[comparedPlayerDict safeObjectForKey:@"Achievements"] integerValue]];
				[game setTotalAchievements:possibleAchievements.integerValue];
				[game setGamertagComparedWith:comparedGamertag];
				[game setRelativeDateStamp:[lastPlayedDate relativeDateStringWithDateFormatter:dateFormatter]];
				[games addObject:game];
			}
		}];
		
		dispatch_async_main_queue(^{callback(games);});
	});
}

@end