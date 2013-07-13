//
//  TIXboxLiveAchievement.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 26/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveAchievement.h"
#import "TIXboxLiveEngineAdditions.h"

@implementation TIXboxLiveAchievement {	
	NSMutableDictionary * _returnDataDict;
}
@synthesize title = _title;
@synthesize info = _info;
@synthesize score = _score;
@synthesize unlockedStatus = _unlockedStatus;
@synthesize tileURL = _tileURL;

- (id)init {
	
	if ((self = [super init])){
		_returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithTitle:(NSString *)aTitle info:(NSString *)someInfo score:(NSInteger)someScore
	 unlockedStatus:(TIXboxLiveAchievementUnlockedStatus)aStatus tileURL:(NSURL *)aURL {
	
	if ((self = [self init])){
		
		_title = [aTitle copy];
		_info = [someInfo copy];
		_score = someScore;
		_unlockedStatus = aStatus;
		_tileURL = [aURL copy];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		_title = [[aDecoder decodeObjectForKey:@"Title"] copy];
		_info = [[aDecoder decodeObjectForKey:@"Info"] copy];
		_score = [aDecoder decodeIntegerForKey:@"Score"];
		_unlockedStatus = [aDecoder decodeIntegerForKey:@"UnlockedStatus"];
		_tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] copy];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_title forKey:@"Title"];
	[aCoder encodeObject:_info forKey:@"Info"];
	[aCoder encodeInteger:_score forKey:@"Score"];
	[aCoder encodeInteger:_unlockedStatus forKey:@"UnlockedStatus"];
	[aCoder encodeObject:_tileURL forKey:@"TileURL"];
}

- (NSString *)unlockedDescription {
	
	if (_unlockedStatus == TIXboxLiveAchievementUnlockedStatusMe) return @"Only you have unlocked this.";
	else if (_unlockedStatus == TIXboxLiveAchievementUnlockedStatusThem) return @"You have not unlocked this.";
	else if (_unlockedStatus == TIXboxLiveAchievementUnlockedStatusBoth) return @"You have both unlocked this.";
	else if (_unlockedStatus == TIXboxLiveAchievementUnlockedStatusNeither) return @"Neither of you have unlocked this.";
	return @"";
}

- (BOOL)isEqual:(id)object {
	return ([object isKindOfClass:[TIXboxLiveAchievement class]] ? [self isEqualToAchievement:object] : [super isEqual:object]);
}

- (BOOL)isEqualToAchievement:(TIXboxLiveAchievement *)achievement {
	return (self == achievement || [achievement.tileURL isEqual:_tileURL]);
}

- (NSComparisonResult)compare:(TIXboxLiveAchievement *)achievement {
	return [_title caseInsensitiveCompare:achievement.title];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveAchievement %p; title = \"%@\">", self, _title];
}

@end