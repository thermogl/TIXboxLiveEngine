//
//  TIXboxLiveEngineConnection.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#define TIXboxLiveEngineConnectionTypeIsLogin(type)				(type == TIXboxLiveEngineConnectionTypeGetLogin || type == TIXboxLiveEngineConnectionTypePostLogin ||\
																 type == TIXboxLiveEngineConnectionTypePostAuth)
#define TIXboxLiveEngineConnectionTypeIsPrimaryGet(type)		(type == TIXboxLiveEngineConnectionTypeGetFriends || type == TIXboxLiveEngineConnectionTypeGetGames ||\
																 type == TIXboxLiveEngineConnectionTypeGetMessages || type == TIXboxLiveEngineConnectionTypeGetRecentPlayers)
#define TIXboxLiveEngineConnectionTypeIsFriends(type)			(type == TIXboxLiveEngineConnectionTypeGetFriends ||\
																 type == TIXboxLiveEngineConnectionTypeGetFriendsVerification)
#define TIXboxLiveEngineConnectionTypeIsGames(type)				(type == TIXboxLiveEngineConnectionTypeGetGames || type == TIXboxLiveEngineConnectionTypeGetGamesVerification)
#define TIXboxLiveEngineConnectionTypeIsRecentPlayers(type)		(type == TIXboxLiveEngineConnectionTypeGetRecentPlayers ||\
																 type == TIXboxLiveEngineConnectionTypeGetRecentPlayersVerification)

typedef enum {
	TIXboxLiveEngineConnectionTypeGetLogin = 0,
	TIXboxLiveEngineConnectionTypePostLogin,
	TIXboxLiveEngineConnectionTypePostAuth,
	TIXboxLiveEngineConnectionTypeGetBasicGamerInfo,
	TIXboxLiveEngineConnectionTypeGetGamerProfile,
	TIXboxLiveEngineConnectionTypeChangeGamerProfile,
	TIXboxLiveEngineConnectionTypeGetFriendGamerTile,
	TIXboxLiveEngineConnectionTypeGetFriendGamerInfo,
	TIXboxLiveEngineConnectionTypeGetFriendsVerification,
	TIXboxLiveEngineConnectionTypeGetFriends,
	TIXboxLiveEngineConnectionTypeGetMessages,
	TIXboxLiveEngineConnectionTypeGetGames,
	TIXboxLiveEngineConnectionTypeGetGamesVerification,
	TIXboxLiveEngineConnectionTypeGetAchievements,
	TIXboxLiveEngineConnectionTypeGetRecentPlayers,
	TIXboxLiveEngineConnectionTypeGetRecentPlayersVerification,
	TIXboxLiveEngineConnectionTypeGetFriendsOfFriend,
	TIXboxLiveEngineConnectionTypeGetGameComparisons,
	TIXboxLiveEngineConnectionTypeGetAchievementComparisons,
	TIXboxLiveEngineConnectionTypeSendMessage,
	TIXboxLiveEngineConnectionTypeSendFriendRequest,
	TIXboxLiveEngineConnectionTypeGetMessageBody,
	TIXboxLiveEngineConnectionTypeGetMessageImage,
	TIXboxLiveEngineConnectionTypeGetTileImage,
} TIXboxLiveEngineConnectionType;

typedef void (^TIXboxLiveEngineConnectionBlock)(NSError * error);
typedef void (^TIXboxLiveEngineFriendsBlock)(NSError * error, NSArray * friends, NSInteger onlineCount);
typedef void (^TIXboxLiveEngineGamesBlock)(NSError * error, NSString * gamertag, NSArray * games);
typedef void (^TIXboxLiveEngineAchievementsBlock)(NSError * error, TIXboxLiveGame * game, NSArray * achievements);
typedef void (^TIXboxLiveEngineRecentPlayersBlock)(NSError * error, NSArray * players);
typedef void (^TIXboxLiveEngineFriendsOfFriendBlock)(NSError * error, NSString * gamertag, NSArray * friends);
typedef void (^TIXboxLiveEngineMessagesBlock)(NSError * error, NSArray * messages);
typedef void (^TIXboxLiveEngineFriendRequestBlock)(NSError * error, NSString * gamertag);
typedef void (^TIXboxLiveEngineMessageSentBlock)(NSError * error, NSArray * recipients);

@interface TIXboxLiveEngineConnection : NSURLConnection {
	
	TIXboxLiveEngineConnectionType type;
	id callback;
	NSDictionary * userInfo;
	NSNumber * backgroundTaskIdentifier;
}

@property (nonatomic, assign) TIXboxLiveEngineConnectionType type;
@property (nonatomic, copy) id callback;
@property (nonatomic, retain) NSDictionary * userInfo;
@property (nonatomic, retain) NSNumber * backgroundTaskIdentifier;
@property (nonatomic, readonly) NSString * typeDescription;

@end