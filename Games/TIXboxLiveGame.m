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
@synthesize title = _title;
@synthesize titleID = _titleID;
@synthesize unlockedScore = _unlockedScore;
@synthesize totalScore = _totalScore;
@synthesize unlockedAchievements = _unlockedAchievements;
@synthesize totalAchievements = _totalAchievements;
@synthesize lastPlayedDate = _lastPlayedDate;
@synthesize tileURL = _tileURL;
@synthesize gamertagComparedWith = _gamertagComparedWith;
@synthesize relativeDateStamp = _relativeDateStamp;

- (id)initWithTitle:(NSString *)aTitle titleID:(NSString *)anID lastPlayedDate:(NSDate *)aDate tileURL:(NSURL *)aURL {
	
	if ((self = [super init])){
		
		_title = [aTitle copy];
		_titleID = [anID copy];
		_lastPlayedDate = [aDate copy];
		_tileURL = [aURL copy];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		_title = [[aDecoder decodeObjectForKey:@"Title"] copy];
		_titleID = [[aDecoder decodeObjectForKey:@"TitleID"] copy];
		_unlockedScore = [[aDecoder decodeObjectForKey:@"UnlockedScore"] integerValue];
		_totalScore = [[aDecoder decodeObjectForKey:@"TotalScore"] integerValue];
		_unlockedAchievements = [[aDecoder decodeObjectForKey:@"UnlockedAchievements"] integerValue];
		_totalAchievements = [[aDecoder decodeObjectForKey:@"TotalAchievements"] integerValue];
		_lastPlayedDate = [[aDecoder decodeObjectForKey:@"LastPlayedDate"] copy];
		_tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] copy];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	
	[aCoder encodeObject:_title forKey:@"Title"];
	[aCoder encodeObject:_titleID forKey:@"TitleID"];
	[aCoder encodeObject:[NSNumber numberWithInteger:_unlockedScore] forKey:@"UnlockedScore"];
	[aCoder encodeObject:[NSNumber numberWithInteger:_totalScore] forKey:@"TotalScore"];
	[aCoder encodeObject:[NSNumber numberWithInteger:_unlockedAchievements] forKey:@"UnlockedAchievements"];
	[aCoder encodeObject:[NSNumber numberWithInteger:_totalAchievements] forKey:@"TotalAchievements"];
	[aCoder encodeObject:_lastPlayedDate forKey:@"LastPlayedDate"];
	[aCoder encodeObject:_tileURL forKey:@"TileURL"];
}

- (NSString *)relativeDateStamp {
	
	if (!_relativeDateStamp) 
		_relativeDateStamp = [[_lastPlayedDate relativeDateString] copy];
	
	return _relativeDateStamp;
}

- (BOOL)isEqual:(id)object {
	return ([object isKindOfClass:[TIXboxLiveGame class]] ? 
			[self isEqualToGame:object] : [super isEqual:object]);
}

- (BOOL)isEqualToGame:(TIXboxLiveGame *)game {
	return (self == game || [_titleID isEqualToString:game.titleID]);
}

- (NSComparisonResult)compare:(TIXboxLiveGame *)aGame {
	return [_title caseInsensitiveCompare:aGame.title];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveGame %p; title = \"%@\"; titleID = \"%@\">", self, _title, _titleID];
}

@end