//
//  TIXboxLiveEngine.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveUser.h"
#import "TIXboxLiveFriend.h"
#import "TIXboxLiveMessage.h"
#import "TIXboxLiveEngineConnection.h"

extern NSString * const TIXboxLiveEngineConnectionBlockKey;
extern NSString * const TIXboxLiveEngineConnectionMessageKey;
extern NSString * const TIXboxLiveEngineConnectionRecipientsKey;
extern NSString * const TIXboxLiveEngineConnectionGamertagKey;
extern NSString * const TIXboxLiveEngineConnectionGameKey;
extern NSString * const TIXboxLiveEngineConnectionTaskIdentifierKey;
extern NSString * const TIXboxLiveEngineDidSignInNotificationName;
extern NSString * const TIXboxLiveEngineDidSignOutNotificationName;
extern NSString * const TIXboxLiveEngineSignInFailedNotificationName;
extern NSString * const TIXboxLiveEngineStateChangedNotificationName;

typedef enum {
	TIXboxLiveEngineErrorCodeIncorrectEmailPassword = -1,
	TIXboxLiveEngineErrorCodeSiteDown = -2,
	TIXboxLiveEngineErrorCodeMessageSendingError = -3,
	TIXboxLiveEngineErrorCodeTermsOfUse = -4,
	TIXboxLiveEngineErrorCodeTimeout = NSURLErrorTimedOut,
	TIXboxLiveEngineErrorCodeUnknownError = -6,
	TIXboxLiveEngineErrorCodeParseError = -7,
} TIXboxLiveEngineErrorCode;

typedef void (^TIXboxLiveEngineSignOutBlock)(BOOL wasExpected);
typedef void (^TIXboxLiveEngineLogBlock)(TIXboxLiveEngineConnection * connection, NSString * response);

@class TIXboxLiveGame;
@interface TIXboxLiveEngine : NSObject {
	
	TIXboxLiveUser * user;
	
	NSMutableDictionary * returnDataDict;
	NSMutableArray * connectionQueue;
	NSMutableArray * parsers;
	
	BOOL signedIn;
	BOOL signingIn;
	BOOL loadingFriends;
	BOOL loadingGames;
	BOOL loadingMessages;
	BOOL loadingRecentPlayers;
	
	NSString * email;
	NSString * password;
	NSString * cookieHash;
	
	NSString * verificationToken;
	NSInteger verificationTokenAttemptCount;
	
	TIXboxLiveEngineSignOutBlock signOutBlock;
	TIXboxLiveEngineLogBlock logBlock;
}

@property (nonatomic, retain) TIXboxLiveUser * user;
@property (nonatomic, readonly) BOOL signedIn;
@property (nonatomic, readonly) BOOL signingIn;
@property (nonatomic, readonly) BOOL loadingFriends;
@property (nonatomic, readonly) BOOL loadingGames;
@property (nonatomic, readonly) BOOL loadingMessages;
@property (nonatomic, readonly) BOOL loadingRecentPlayers;
@property (nonatomic, readonly, copy) NSString * email;
@property (nonatomic, readonly, copy) NSString * password;
@property (nonatomic, readonly, copy) NSString * cookieHash;
@property (nonatomic, copy) TIXboxLiveEngineSignOutBlock signOutBlock;
@property (nonatomic, copy) TIXboxLiveEngineLogBlock logBlock;

- (void)signInWithEmail:(NSString *)anEmail password:(NSString *)aPassword callback:(TIXboxLiveEngineConnectionBlock)block;
- (void)signOut;

- (void)getFriendsWithCallback:(TIXboxLiveEngineFriendsBlock)callback;
- (void)getRecentPlayersWithCallback:(TIXboxLiveEngineRecentPlayersBlock)callback;
- (void)getFriendsOfFriend:(NSString *)gamertag callback:(TIXboxLiveEngineFriendsOfFriendBlock)callback;
- (void)sendFriendRequestToGamer:(NSString *)gamertag callback:(TIXboxLiveEngineFriendRequestBlock)callback;

- (void)getGamesWithCallback:(TIXboxLiveEngineGamesBlock)callback;
- (void)getAchievementsForGame:(TIXboxLiveGame *)game callback:(TIXboxLiveEngineAchievementsBlock)callback;
- (void)getGamesComparedWithGamer:(NSString *)gamertag callback:(TIXboxLiveEngineGamesBlock)callback;
- (void)getAchievementsComparisonsForGame:(TIXboxLiveGame *)game callback:(TIXboxLiveEngineAchievementsBlock)callback;

- (void)getMessagesWithCallback:(TIXboxLiveEngineMessagesBlock)callback;
- (void)sendMessage:(NSString *)message toRecipients:(NSArray *)recipients callback:(TIXboxLiveEngineMessageSentBlock)callback;

@end