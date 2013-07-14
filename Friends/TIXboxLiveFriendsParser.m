//
//  TIXboxLiveFriendsParser.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveFriendsParser.h"
#import "TIXboxLiveFriend.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIXboxLiveEngineConnection.h"

@implementation TIXboxLiveFriendsParser

- (void)parseFriendsPage:(NSString *)aPage callback:(TIXboxLiveFriendsParserFriendsBlock)callback {
	
	/*GamerScore = 25089;
	 GamerTag = "Imperial Black";
	 GamerTileUrl = "http://image.xboxlive.com/global/t.434d07e9/tile/0/18002";
	 IsOnline = 0;
	 LargeGamerTileUrl = "http://image.xboxlive.com/global/t.434d07e9/tile/0/28002";
	 LastSeen = "/Date(1320923283000)/";
	 Presence = "Last seen 11 hours ago playing Sky Player";
	 RichPresence = "";
	 TitleInfo =         {
	 Id = 1481115614;
	 Name = "Sky Player";
	 */

	dispatch_async_serial("com.TIXboxLiveEngine.FriendsParseQueue", ^{
		
		NSMutableArray * onlineFriends = [NSMutableArray array];
		NSMutableArray * offlineFriends = [NSMutableArray array];
		NSMutableArray * friendRequests = [NSMutableArray array];
		
		NSDateFormatter * inputFormatter = [[NSDateFormatter alloc] init];
		[inputFormatter setDateFormat:@"dd/MM/yyyy"];
		NSDateFormatter * outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateStyle:NSDateFormatterShortStyle];
		
		NSDictionary * friendsData = [(NSDictionary *)[aPage objectFromJSONString] safeObjectForKey:@"Data"];
		
		NSArray * rawFriends = [friendsData	safeObjectForKey:@"Friends"];
		[rawFriends enumerateObjectsUsingBlock:^(NSDictionary * friendDict, NSUInteger idx, BOOL *stop){
			
			BOOL isOnline = [[friendDict safeObjectForKey:@"IsOnline"] boolValue];
			
			NSString * gamertag = [friendDict safeObjectForKey:@"GamerTag"];
			NSString * info = [[friendDict safeObjectForKey:@"Presence"] stringByCorrectingDateRelativeToLocaleWithInputFormatter:inputFormatter 
																												  outputFormatter:outputFormatter];
			NSURL * tileURL = [NSURL URLWithString:[friendDict safeObjectForKey:@"LargeGamerTileUrl"]];
			
			TIXboxLiveFriendStatus status = isOnline ? TIXboxLiveFriendStatusOnline : TIXboxLiveFriendStatusOffline;
			
			TIXboxLiveFriend * friend = [[TIXboxLiveFriend alloc] initWithGamertag:gamertag info:info status:status tileURL:tileURL];
			[friend setFriendRequestType:TIXboxLiveFriendRequestTypeNone];
			[friend setVerificationToken:self.verificationToken];
			[friend setCookieHash:self.cookieHash];
			[(isOnline ? onlineFriends : offlineFriends) addObject:friend];
		}];
		
		rawFriends = [friendsData safeObjectForKey:@"Outgoing"];
		[rawFriends enumerateObjectsUsingBlock:^(NSDictionary * friendDict, NSUInteger idx, BOOL *stop){
			
			NSString * gamertag = [friendDict safeObjectForKey:@"GamerTag"];
			NSURL * tileURL = [NSURL URLWithString:[friendDict safeObjectForKey:@"LargeGamerTileUrl"]];
			
			TIXboxLiveFriend * friend = [[TIXboxLiveFriend alloc] initWithGamertag:gamertag info:@"Friend request sent" 
																			status:TIXboxLiveFriendStatusRequest tileURL:tileURL];
			[friend setFriendRequestType:TIXboxLiveFriendRequestTypeOutgoing];
			[friend setVerificationToken:self.verificationToken];
			[friend setCookieHash:self.cookieHash];
			[friendRequests addObject:friend];
		}];
		
		rawFriends = [friendsData safeObjectForKey:@"Incoming"];
		[rawFriends enumerateObjectsUsingBlock:^(NSDictionary * friendDict, NSUInteger idx, BOOL *stop){
			
			NSString * gamertag = [friendDict safeObjectForKey:@"GamerTag"];
			NSURL * tileURL = [NSURL URLWithString:[friendDict safeObjectForKey:@"LargeGamerTileUrl"]];
			
			TIXboxLiveFriend * friend = [[TIXboxLiveFriend alloc] initWithGamertag:gamertag info:@"Wants to be your friend" 
																			status:TIXboxLiveFriendStatusRequest tileURL:tileURL];
			[friend setFriendRequestType:TIXboxLiveFriendRequestTypeIncoming];
			[friend setVerificationToken:self.verificationToken];
			[friend setCookieHash:self.cookieHash];
			[friendRequests addObject:friend];
		}];
		
		[onlineFriends sortUsingSelector:@selector(compare:)];
		[offlineFriends sortUsingSelector:@selector(compare:)];
		[friendRequests sortUsingSelector:@selector(compare:)];
		
		dispatch_async_main_queue(^{callback(onlineFriends, offlineFriends, friendRequests);});
	});
}

- (void)parseRecentPlayersPage:(NSString *)aPage callback:(TIXboxLiveFriendsParserRecentPlayersBlock)callback {

	dispatch_async_serial("com.TIXboxLiveEngine.RecentPlayersParseQueue", ^{
		
		NSDateFormatter * inputFormatter = [[NSDateFormatter alloc] init];
		[inputFormatter setDateFormat:@"dd/MM/yyyy"];
		NSDateFormatter * outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateStyle:NSDateFormatterShortStyle];
		
		NSMutableArray * players = [NSMutableArray array];
		
		NSArray * rawPlayers = [(NSDictionary *)[aPage objectFromJSONString] safeObjectForKey:@"Data"];
		[rawPlayers enumerateObjectsUsingBlock:^(NSDictionary * playerDict, NSUInteger idx, BOOL *stop){
			
			NSString * gamertag = [playerDict safeObjectForKey:@"GamerTag"];
			NSString * info = [[playerDict safeObjectForKey:@"Presence"] stringByCorrectingDateRelativeToLocaleWithInputFormatter:inputFormatter 
																												  outputFormatter:outputFormatter];
			NSURL * tileURL = [NSURL URLWithString:[playerDict safeObjectForKey:@"LargeGamerTileUrl"]];
			
			TIXboxLiveFriend * friend = [[TIXboxLiveFriend alloc] initWithGamertag:gamertag info:info status:TIXboxLiveFriendStatusUnknown tileURL:tileURL];
			[friend setFriendRequestType:TIXboxLiveFriendRequestTypeNone];
			[friend setIsOnFriendsList:NO];
			[friend setVerificationToken:self.verificationToken];
			[friend setCookieHash:self.cookieHash];
			[players addObject:friend];
		}];
		
		[players sortUsingSelector:@selector(compare:)];
		dispatch_async_main_queue(^{callback(players);});
	});
}

- (void)parseFriendsOfFriendPage:(NSString *)aPage callback:(TIXboxLiveFriendsParserFriendsOfFriendsBlock)callback {
	
	dispatch_async_serial("com.TIXboxLiveEngine.FriendsOfFriendParseQueue", ^{
		
		NSMutableArray * friends = [NSMutableArray array];
		
		NSDictionary * friendsData = [(NSDictionary *)[aPage objectFromJSONString] safeObjectForKey:@"Data"];
		NSArray * rawFriends = [friendsData	safeObjectForKey:@"Friends"];
		
		[rawFriends enumerateObjectsUsingBlock:^(NSDictionary * friendDict, NSUInteger idx, BOOL *stop){
			
			NSString * gamertag = [friendDict safeObjectForKey:@"GamerTag"];
			NSURL * tileURL = [NSURL URLWithString:[friendDict safeObjectForKey:@"LargeGamerTileUrl"]];
			
			TIXboxLiveFriend * friend = [[TIXboxLiveFriend alloc] initWithGamertag:gamertag info:@"Unknown" status:TIXboxLiveFriendStatusUnknown tileURL:tileURL];
			[friend setFriendRequestType:TIXboxLiveFriendRequestTypeNone];
			[friend setIsOnFriendsList:NO];
			[friend setVerificationToken:self.verificationToken];
			[friend setCookieHash:self.cookieHash];
			[friends addObject:friend];
		}];
		
		[friends sortUsingSelector:@selector(compare:)];
		dispatch_async_main_queue(^{callback(friends);});
	});
}

@end