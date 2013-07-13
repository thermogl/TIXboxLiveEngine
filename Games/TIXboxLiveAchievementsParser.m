//
//  TIXboxLiveAchievementsParser.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveAchievementsParser.h"
#import "TIXboxLiveAchievement.h"
#import "TIXboxLiveEngineAdditions.h"

@implementation TIXboxLiveAchievementsParser

- (void)parseAchievementsPage:(NSString *)aPage callback:(TIXboxLiveAchievementsParserAchievementsBlock)callback {
	
	dispatch_async_serial("com.TIXboxLiveEngine.AchievementParseQueue", ^{
		
		NSMutableArray * achievements = [NSMutableArray array];
		
		NSString * achievementsJSON = [aPage stringBetween:@"broker.publish(routes.activity.details.load, " and:@");"];
		NSArray * rawAchievements = [(NSDictionary *)[achievementsJSON objectFromJSONString] safeObjectForKey:@"Achievements"];
		[rawAchievements enumerateObjectsUsingBlock:^(NSDictionary * rawAchievement, NSUInteger idx, BOOL *stop){
			
			BOOL isHidden = [[rawAchievement safeObjectForKey:@"IsHidden"] boolValue];
			NSString * name = isHidden ? @"Secret Achievement" : [rawAchievement safeObjectForKey:@"Name"];
			NSString * description = isHidden ? @"Continue playing to unlock this secret achievement." : [rawAchievement safeObjectForKey:@"Description"];
			
			TIXboxLiveAchievementUnlockedStatus status = TIXboxLiveAchievementUnlockedStatusNeither;
			if ([[(NSDictionary *)[rawAchievement safeObjectForKey:@"EarnDates"] allKeys] count]) status = TIXboxLiveAchievementUnlockedStatusMe;
			
			NSURL * tileURL = [NSURL URLWithString:[rawAchievement safeObjectForKey:@"TileUrl"]];
			TIXboxLiveAchievement * achievement = [[TIXboxLiveAchievement alloc] initWithTitle:name
																						  info:description 
																						score:[[rawAchievement safeObjectForKey:@"Score"] integerValue]
																				unlockedStatus:status 
																					   tileURL:tileURL];
			[achievements addObject:achievement];
		}];
		
		dispatch_async_main_queue(^{callback(achievements);});
	});
}

- (void)parseAchievementComparisonsPage:(NSString *)aPage callback:(TIXboxLiveAchievementsParserAchievementsBlock)callback {
	
	dispatch_async_serial("com.TIXboxLiveEngine.AchievementComparisonParseQueue", ^{
		
		NSMutableArray * achievements = [NSMutableArray array];
		
		NSString * achievementsJSON = [aPage stringBetween:@"broker.publish(routes.activity.details.load, " and:@");"];
		NSDictionary * achievementsData = (NSDictionary *)[achievementsJSON objectFromJSONString];
		NSArray * rawAchievements = [achievementsData safeObjectForKey:@"Achievements"];
		[rawAchievements enumerateObjectsUsingBlock:^(NSDictionary * rawAchievement, NSUInteger idx, BOOL *stop){
			
			BOOL isHidden = [[rawAchievement safeObjectForKey:@"IsHidden"] boolValue];
			NSString * name = isHidden ? @"Secret Achievement" : [rawAchievement safeObjectForKey:@"Name"];
			NSString * description = isHidden ? @"Continue playing to unlock this secret achievement." : [rawAchievement safeObjectForKey:@"Description"];
			
			TIXboxLiveAchievementUnlockedStatus status = TIXboxLiveAchievementUnlockedStatusNeither;
			NSArray * keys = [(NSDictionary *)[rawAchievement safeObjectForKey:@"EarnDates"] allKeys];
			
			if (keys.count == 1){
				status = [[keys objectAtIndex:0] isEqualToString:[achievementsData safeObjectForKey:@"CurrentGamertag"]] ?
				TIXboxLiveAchievementUnlockedStatusMe : TIXboxLiveAchievementUnlockedStatusThem;
			} else if (keys.count == 2) status = TIXboxLiveAchievementUnlockedStatusBoth;
			
			NSURL * tileURL = [NSURL URLWithString:[rawAchievement safeObjectForKey:@"TileUrl"]];
			TIXboxLiveAchievement * achievement = [[TIXboxLiveAchievement alloc] initWithTitle:name
																						  info:description 
																						score:[[rawAchievement safeObjectForKey:@"Score"] integerValue]
																				unlockedStatus:status 
																					   tileURL:tileURL];
			[achievements addObject:achievement];
		}];
		
		dispatch_async_main_queue(^{callback(achievements);});
	});
}

@end