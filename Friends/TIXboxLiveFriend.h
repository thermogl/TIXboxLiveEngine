//
//  TIXboxLiveFriend.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieBase.h"

typedef enum {
	TIXboxLiveFriendStatusUnknown = 0,
	TIXboxLiveFriendStatusOnline,
	TIXboxLiveFriendStatusOffline,
	TIXboxLiveFriendStatusRequest,
} TIXboxLiveFriendStatus;

typedef enum {
	TIXboxLiveFriendRequestTypeNone = 0,
	TIXboxLiveFriendRequestTypeIncoming,
	TIXboxLiveFriendRequestTypeOutgoing,
} TIXboxLiveFriendRequestType;

typedef void (^TIXboxLiveFriendGamerInfoBlock)(NSError * error, NSString * name, NSString * motto, 
											   NSString * location, NSString * bio, NSString * gamerscore, NSString * info);

@interface TIXboxLiveFriend : TIXboxLiveEngineCookieBase <NSCoding, NSCopying>
@property (nonatomic, copy) NSString * gamertag;
@property (nonatomic, copy) NSString * info;
@property (nonatomic, assign) TIXboxLiveFriendStatus status;
@property (nonatomic, copy) NSURL * tileURL;
@property (nonatomic, copy) NSURL * avatarURL;
@property (nonatomic, assign) TIXboxLiveFriendRequestType friendRequestType;
@property (nonatomic, assign) BOOL isOnFriendsList;
@property (nonatomic, readonly) NSString * game;

- (id)initWithGamertag:(NSString *)aGamertag info:(NSString *)someInfo status:(TIXboxLiveFriendStatus)someStatus tileURL:(NSURL *)aURL;
+ (TIXboxLiveFriend *)friendWithGamertag:(NSString *)aGamertag;

- (void)getGamerInfoWithCallback:(TIXboxLiveFriendGamerInfoBlock)callback;

- (NSString *)statusDescription;

- (NSComparisonResult)statusInsensitiveCompare:(TIXboxLiveFriend *)aFriend;

- (BOOL)isEqualToFriend:(TIXboxLiveFriend *)aFriend;
- (BOOL)hasGamertag:(NSString *)aGamertag;
- (BOOL)removeFriend;
- (BOOL)handleFriendRequest:(BOOL)shouldAccept;

- (BOOL)changedGame:(TIXboxLiveFriend *)oldFriend;

- (NSDictionary *)dictRepresentation;

@end
