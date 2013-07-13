//
//  TIXboxLiveEngineConnection.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineConnection.h"

@implementation TIXboxLiveEngineConnection
@synthesize type = _type;
@synthesize callback = _callback;
@synthesize userInfo = _userInfo;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;

- (void)start {
	[self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[super start];
}

- (NSString *)typeDescription {
	
	if (_type == TIXboxLiveEngineConnectionTypeGetLogin) return @"GetLogin";
	else if (_type == TIXboxLiveEngineConnectionTypePostLogin) return @"PostLogin";
	else if (_type == TIXboxLiveEngineConnectionTypePostAuth) return @"PostAuth";
	else if (_type == TIXboxLiveEngineConnectionTypeGetBasicGamerInfo) return @"GetBasicGamerInfo";
	else if (_type == TIXboxLiveEngineConnectionTypeGetGamerProfile) return @"GetGamerProfile";
	else if (_type == TIXboxLiveEngineConnectionTypeChangeGamerProfile) return @"ChangeGamerProfile";
	else if (_type == TIXboxLiveEngineConnectionTypeGetFriendGamerTile) return @"GetFriendGamerTile";
	else if (_type == TIXboxLiveEngineConnectionTypeGetFriendGamerInfo) return @"GetFriendGamerInfo";
	else if (_type == TIXboxLiveEngineConnectionTypeGetFriendsVerification) return @"GetFriendsVerification";
	else if (_type == TIXboxLiveEngineConnectionTypeGetFriends) return @"GetFriends";
	else if (_type == TIXboxLiveEngineConnectionTypeGetMessages) return @"GetMessages";
	else if (_type == TIXboxLiveEngineConnectionTypeGetGames) return @"GetGames";
	else if (_type == TIXboxLiveEngineConnectionTypeGetGamesVerification) return @"GetGamesVerification";
	else if (_type == TIXboxLiveEngineConnectionTypeGetAchievements) return @"GetAchievements";
	else if (_type == TIXboxLiveEngineConnectionTypeGetRecentPlayers) return @"GetRecentPlayers";
	else if (_type == TIXboxLiveEngineConnectionTypeGetRecentPlayersVerification) return @"GetRecentPlayersVerification";
	else if (_type == TIXboxLiveEngineConnectionTypeGetFriendsOfFriend) return @"GetFriendsOfFriend";
	else if (_type == TIXboxLiveEngineConnectionTypeGetGameComparisons) return @"GetGameComparisons";
	else if (_type == TIXboxLiveEngineConnectionTypeGetAchievementComparisons) return @"GetAchievementComparisons";
	else if (_type == TIXboxLiveEngineConnectionTypeSendMessage) return @"SendMessage";
	else if (_type == TIXboxLiveEngineConnectionTypeSendFriendRequest) return @"SendFriendRequest";
	else if (_type == TIXboxLiveEngineConnectionTypeGetMessageBody) return @"GetMessageBody";
	else if (_type == TIXboxLiveEngineConnectionTypeGetMessageImage) return @"GetMessageImage";
	else if (_type == TIXboxLiveEngineConnectionTypeGetTileImage) return @"GetTileImage";
	else return @"";
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveEngineConnection %p; type: %@>", self, self.typeDescription];
}

@end