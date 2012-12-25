//
//  TIXboxLiveEngineConnection.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineConnection.h"

@implementation TIXboxLiveEngineConnection
@synthesize type;
@synthesize callback;
@synthesize userInfo;
@synthesize backgroundTaskIdentifier;

- (void)start {
	[self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[super start];
}

- (NSString *)typeDescription {
	
	if (type == TIXboxLiveEngineConnectionTypeGetLogin) return @"GetLogin";
	else if (type == TIXboxLiveEngineConnectionTypePostLogin) return @"PostLogin";
	else if (type == TIXboxLiveEngineConnectionTypePostAuth) return @"PostAuth";
	else if (type == TIXboxLiveEngineConnectionTypeGetBasicGamerInfo) return @"GetBasicGamerInfo";
	else if (type == TIXboxLiveEngineConnectionTypeGetGamerProfile) return @"GetGamerProfile";
	else if (type == TIXboxLiveEngineConnectionTypeChangeGamerProfile) return @"ChangeGamerProfile";
	else if (type == TIXboxLiveEngineConnectionTypeGetFriendGamerTile) return @"GetFriendGamerTile";
	else if (type == TIXboxLiveEngineConnectionTypeGetFriendGamerInfo) return @"GetFriendGamerInfo";
	else if (type == TIXboxLiveEngineConnectionTypeGetFriendsVerification) return @"GetFriendsVerification";
	else if (type == TIXboxLiveEngineConnectionTypeGetFriends) return @"GetFriends";
	else if (type == TIXboxLiveEngineConnectionTypeGetMessages) return @"GetMessages";
	else if (type == TIXboxLiveEngineConnectionTypeGetGames) return @"GetGames";
	else if (type == TIXboxLiveEngineConnectionTypeGetGamesVerification) return @"GetGamesVerification";
	else if (type == TIXboxLiveEngineConnectionTypeGetAchievements) return @"GetAchievements";
	else if (type == TIXboxLiveEngineConnectionTypeGetRecentPlayers) return @"GetRecentPlayers";
	else if (type == TIXboxLiveEngineConnectionTypeGetRecentPlayersVerification) return @"GetRecentPlayersVerification";
	else if (type == TIXboxLiveEngineConnectionTypeGetFriendsOfFriend) return @"GetFriendsOfFriend";
	else if (type == TIXboxLiveEngineConnectionTypeGetGameComparisons) return @"GetGameComparisons";
	else if (type == TIXboxLiveEngineConnectionTypeGetAchievementComparisons) return @"GetAchievementComparisons";
	else if (type == TIXboxLiveEngineConnectionTypeSendMessage) return @"SendMessage";
	else if (type == TIXboxLiveEngineConnectionTypeSendFriendRequest) return @"SendFriendRequest";
	else if (type == TIXboxLiveEngineConnectionTypeGetMessageBody) return @"GetMessageBody";
	else if (type == TIXboxLiveEngineConnectionTypeGetMessageImage) return @"GetMessageImage";
	else if (type == TIXboxLiveEngineConnectionTypeGetTileImage) return @"GetTileImage";
	else return @"";
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveEngineConnection %p; type: %@>", self, self.typeDescription];
}

- (void)dealloc {
	[callback release];
	[userInfo release];
	[backgroundTaskIdentifier release];
	[super dealloc];
}

@end