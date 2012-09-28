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
	if (type == TIXboxLiveEngineConnectionTypePostLogin) return @"PostLogin";
	if (type == TIXboxLiveEngineConnectionTypePostAuth) return @"PostAuth";
	if (type == TIXboxLiveEngineConnectionTypeGetBasicGamerInfo) return @"GetBasicGamerInfo";
	if (type == TIXboxLiveEngineConnectionTypeGetGamerProfile) return @"GetGamerProfile";
	if (type == TIXboxLiveEngineConnectionTypeChangeGamerProfile) return @"ChangeGamerProfile";
	if (type == TIXboxLiveEngineConnectionTypeGetFriendGamerTile) return @"GetFriendGamerTile";
	if (type == TIXboxLiveEngineConnectionTypeGetFriendGamerInfo) return @"GetFriendGamerInfo";
	if (type == TIXboxLiveEngineConnectionTypeGetFriendsVerification) return @"GetFriendsVerification";
	if (type == TIXboxLiveEngineConnectionTypeGetFriends) return @"GetFriends";
	if (type == TIXboxLiveEngineConnectionTypeGetMessages) return @"GetMessages";
	if (type == TIXboxLiveEngineConnectionTypeGetGames) return @"GetGames";
	if (type == TIXboxLiveEngineConnectionTypeGetGamesVerification) return @"GetGamesVerification";
	if (type == TIXboxLiveEngineConnectionTypeGetAchievements) return @"GetAchievements";
	if (type == TIXboxLiveEngineConnectionTypeGetRecentPlayers) return @"GetRecentPlayers";
	if (type == TIXboxLiveEngineConnectionTypeGetRecentPlayersVerification) return @"GetRecentPlayersVerification";
	if (type == TIXboxLiveEngineConnectionTypeGetFriendsOfFriend) return @"GetFriendsOfFriend";
	if (type == TIXboxLiveEngineConnectionTypeGetGameComparisons) return @"GetGameComparisons";
	if (type == TIXboxLiveEngineConnectionTypeGetAchievementComparisons) return @"GetAchievementComparisons";
	if (type == TIXboxLiveEngineConnectionTypeSendMessage) return @"SendMessage";
	if (type == TIXboxLiveEngineConnectionTypeSendFriendRequest) return @"SendFriendRequest";
	if (type == TIXboxLiveEngineConnectionTypeGetMessageBody) return @"GetMessageBody";
	if (type == TIXboxLiveEngineConnectionTypeGetMessageImage) return @"GetMessageImage";
	if (type == TIXboxLiveEngineConnectionTypeGetTileImage) return @"GetTileImage";
	
	return @"";
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