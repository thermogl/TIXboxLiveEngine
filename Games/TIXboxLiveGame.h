//
//  TIXboxLiveGame.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 25/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

@interface TIXboxLiveGame : NSObject <NSCoding>
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * titleID;
@property (nonatomic, assign) NSInteger unlockedScore;
@property (nonatomic, assign) NSInteger totalScore;
@property (nonatomic, assign) NSInteger unlockedAchievements;
@property (nonatomic, assign) NSInteger totalAchievements;
@property (nonatomic, copy) NSDate * lastPlayedDate;
@property (nonatomic, copy) NSURL * tileURL;
@property (nonatomic, copy) NSString * gamertagComparedWith;
@property (nonatomic, copy) NSString * relativeDateStamp;

- (id)initWithTitle:(NSString *)aTitle titleID:(NSString *)anID lastPlayedDate:(NSDate *)aDate tileURL:(NSURL *)tileURL;
- (NSString *)relativeDateStamp;
- (BOOL)isEqualToGame:(TIXboxLiveGame *)game;

@end
