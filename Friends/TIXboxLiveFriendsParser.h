//
//  TIXboxLiveFriendsParser.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieBase.h"

typedef void (^TIXboxLiveFriendsParserFriendsBlock)(NSArray * onlineFriends, NSArray * offlineFriends, NSArray * friendRequests);
typedef void (^TIXboxLiveFriendsParserRecentPlayersBlock)(NSArray * players);
typedef void (^TIXboxLiveFriendsParserFriendsOfFriendsBlock)(NSArray * friends);

@interface TIXboxLiveFriendsParser : TIXboxLiveEngineCookieBase 
- (void)parseFriendsPage:(NSString *)aPage callback:(TIXboxLiveFriendsParserFriendsBlock)callback;
- (void)parseRecentPlayersPage:(NSString *)aPage callback:(TIXboxLiveFriendsParserRecentPlayersBlock)callback;
- (void)parseFriendsOfFriendPage:(NSString *)aPage callback:(TIXboxLiveFriendsParserFriendsOfFriendsBlock)callback;
@end
