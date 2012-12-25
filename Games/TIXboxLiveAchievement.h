//
//  TIXboxLiveAchievement.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

typedef enum {
	TIXboxLiveAchievementUnlockedStatusMe = 0,
	TIXboxLiveAchievementUnlockedStatusThem = 1,
	TIXboxLiveAchievementUnlockedStatusBoth = 2,
	TIXboxLiveAchievementUnlockedStatusNeither = 3,
} TIXboxLiveAchievementUnlockedStatus;

@interface TIXboxLiveAchievement : NSObject <NSCoding> {

	NSString * title;
	NSString * info;
	NSInteger score;
	TIXboxLiveAchievementUnlockedStatus unlockedStatus;
	NSURL * tileURL;
	
	NSMutableDictionary * returnDataDict;
}

@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * info;
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) TIXboxLiveAchievementUnlockedStatus unlockedStatus;
@property (nonatomic, copy) NSURL * tileURL;
@property (nonatomic, readonly) NSString * unlockedDescription;

- (id)initWithTitle:(NSString *)aTitle info:(NSString *)someInfo score:(NSInteger)someScore
	 unlockedStatus:(TIXboxLiveAchievementUnlockedStatus)aStatus tileURL:(NSURL *)tileURL;

- (BOOL)isEqualToAchievement:(TIXboxLiveAchievement *)achievement;

@end
