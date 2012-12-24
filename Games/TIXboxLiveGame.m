//
//  TIXboxLiveGame.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 25/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveGame.h"
#import "TIXboxLiveEngineAdditions.h"

@interface TIXboxLiveGame (Private)
- (void)downloadTileFromURL:(NSURL *)tileURL;
@end

@implementation TIXboxLiveGame
@synthesize title;
@synthesize titleID;
@synthesize unlockedScore;
@synthesize totalScore;
@synthesize unlockedAchievements;
@synthesize totalAchievements;
@synthesize lastPlayedDate;
@synthesize tileURL;
@synthesize gamertagComparedWith;
@synthesize relativeDateStamp;

- (id)initWithTitle:(NSString *)aTitle titleID:(NSString *)anID lastPlayedDate:(NSDate *)aDate tileURL:(NSURL *)aURL {
	
	if ((self = [super init])){
		
		title = [aTitle copy];
		titleID = [anID copy];
		lastPlayedDate = [aDate copy];
		tileURL = [aURL retain];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		title = [[aDecoder decodeObjectForKey:@"Title"] retain];
		titleID = [[aDecoder decodeObjectForKey:@"TitleID"] retain];
		unlockedScore = [[aDecoder decodeObjectForKey:@"UnlockedScore"] integerValue];
		totalScore = [[aDecoder decodeObjectForKey:@"TotalScore"] integerValue];
		unlockedAchievements = [[aDecoder decodeObjectForKey:@"UnlockedAchievements"] integerValue];
		totalAchievements = [[aDecoder decodeObjectForKey:@"TotalAchievements"] integerValue];
		lastPlayedDate = [[aDecoder decodeObjectForKey:@"LastPlayedDate"] retain];
		tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] retain];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	
	[aCoder encodeObject:title forKey:@"Title"];
	[aCoder encodeObject:titleID forKey:@"TitleID"];
	[aCoder encodeObject:[NSNumber numberWithInteger:unlockedScore] forKey:@"UnlockedScore"];
	[aCoder encodeObject:[NSNumber numberWithInteger:totalScore] forKey:@"TotalScore"];
	[aCoder encodeObject:[NSNumber numberWithInteger:unlockedAchievements] forKey:@"UnlockedAchievements"];
	[aCoder encodeObject:[NSNumber numberWithInteger:totalAchievements] forKey:@"TotalAchievements"];
	[aCoder encodeObject:lastPlayedDate forKey:@"LastPlayedDate"];
	[aCoder encodeObject:tileURL forKey:@"TileURL"];
}

- (NSString *)relativeDateStamp {
	
	if (!relativeDateStamp) 
		relativeDateStamp = [[lastPlayedDate relativeDateString] copy];
	
	return relativeDateStamp;
}

- (BOOL)isEqual:(id)object {
	return ([object isKindOfClass:[TIXboxLiveGame class]] ? 
			[self isEqualToGame:object] : [super isEqual:object]);
}

- (BOOL)isEqualToGame:(TIXboxLiveGame *)game {
	return (self == game || [titleID isEqualToString:game.titleID]);
}

- (NSComparisonResult)compare:(TIXboxLiveGame *)aGame {
	return [title caseInsensitiveCompare:aGame.title];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveGame %p; title = \"%@\"; titleID = \"%@\">", self, title, titleID];
}

- (void)dealloc {
	[title release];
	[titleID release];
	[lastPlayedDate release];
	[gamertagComparedWith release];
	[relativeDateStamp release];
	[tileURL release];
	[super dealloc];
}

@end