//
//  TIXboxLiveAchievement.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveAchievement.h"
#import "TIXboxLiveEngineAdditions.h"

@implementation TIXboxLiveAchievement
@synthesize title;
@synthesize info;
@synthesize score;
@synthesize unlockedStatus;
@synthesize tileURL;

- (id)init {
	
	if ((self = [super init])){
		returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithTitle:(NSString *)aTitle info:(NSString *)someInfo score:(NSInteger)someScore
	 unlockedStatus:(TIXboxLiveAchievementUnlockedStatus)aStatus tileURL:(NSURL *)aURL {
	
	if ((self = [self init])){
		
		title = [aTitle copy];
		info = [someInfo copy];
		score = someScore;
		unlockedStatus = aStatus;
		tileURL = [aURL retain];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		title = [[aDecoder decodeObjectForKey:@"Title"] copy];
		info = [[aDecoder decodeObjectForKey:@"Info"] copy];
		score = [aDecoder decodeIntegerForKey:@"Score"];
		unlockedStatus = [aDecoder decodeIntegerForKey:@"UnlockedStatus"];
		tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] retain];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:title forKey:@"Title"];
	[aCoder encodeObject:info forKey:@"Info"];
	[aCoder encodeInteger:score forKey:@"Score"];
	[aCoder encodeInteger:unlockedStatus forKey:@"UnlockedStatus"];
	[aCoder encodeObject:tileURL forKey:@"TileURL"];
}

- (NSString *)unlockedDescription {
	
	if (unlockedStatus == TIXboxLiveAchievementUnlockedStatusMe) return @"Only you have unlocked this.";
	else if (unlockedStatus == TIXboxLiveAchievementUnlockedStatusThem) return @"You have not unlocked this.";
	else if (unlockedStatus == TIXboxLiveAchievementUnlockedStatusBoth) return @"You have both unlocked this.";
	else if (unlockedStatus == TIXboxLiveAchievementUnlockedStatusNeither) return @"Neither of you have unlocked this.";
	return @"";
}

- (BOOL)isEqual:(id)object {
	return ([object isKindOfClass:[TIXboxLiveAchievement class]] ? [self isEqualToAchievement:object] : [super isEqual:object]);
}

- (BOOL)isEqualToAchievement:(TIXboxLiveAchievement *)achievement {
	return (self == achievement || [achievement.tileURL isEqual:tileURL]);
}

- (NSComparisonResult)compare:(TIXboxLiveAchievement *)achievement {
	return [title caseInsensitiveCompare:achievement.title];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveAchievement %p; title = \"%@\">", self, title];
}

- (void)dealloc {
	[title release];
	[returnDataDict release];
	[info release];
	[tileURL release];
	[super dealloc];
}

@end