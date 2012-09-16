//
//  TIXboxLiveAchievementsParser.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

typedef void (^TIXboxLiveAchievementsParserAchievementsBlock)(NSArray * achievements);

@interface TIXboxLiveAchievementsParser : NSObject 
- (void)parseAchievementsPage:(NSString *)aPage callback:(TIXboxLiveAchievementsParserAchievementsBlock)callback;
- (void)parseAchievementComparisonsPage:(NSString *)aPage callback:(TIXboxLiveAchievementsParserAchievementsBlock)callback;
@end