//
//  TIXboxLiveEngine.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngine.h"
#import "TIXboxLiveFriendsParser.h"
#import "TIXboxLiveGamesParser.h"
#import "TIXboxLiveAchievementsParser.h"
#import "TIXboxLiveMessagesParser.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIURLRequestParameter.h"
#import "TIXboxLiveGame.h"
#import "TIXboxLiveEngineCookieStorage.h"

NSString * const kTIXboxLiveEngineErrorDomain = @"TIXboxLiveEngineErrorDomain";
NSString * const kTIXboxLiveEngineUnknownErrorMessage = @"An unknown error occurred.";
NSString * const kTIXboxLiveEngineJavascriptCheck = @"JavaScript required to sign in";

NSString * const TIXboxLiveEngineConnectionBlockKey = @"TIXboxLiveEngineConnectionBlockKey";
NSString * const TIXboxLiveEngineConnectionMessageKey = @"TIXboxLiveEngineConnectionMessageKey";
NSString * const TIXboxLiveEngineConnectionRecipientsKey = @"TIXboxLiveEngineConnectionRecipientsKey";
NSString * const TIXboxLiveEngineConnectionGamertagKey = @"TIXboxLiveEngineConnectionGamertagKey";
NSString * const TIXboxLiveEngineConnectionGameKey = @"TIXboxLiveEngineConnectionGameKey";
NSString * const TIXboxLiveEngineConnectionTaskIdentifierKey = @"TIXboxLiveEngineConnectionTaskIdentifierKey";
NSString * const TIXboxLiveEngineDidSignInNotificationName = @"TIXboxLiveEngineDidSignIn";
NSString * const TIXboxLiveEngineDidSignOutNotificationName = @"TIXboxLiveEngineDidSignOut";
NSString * const TIXboxLiveEngineSignInFailedNotificationName = @"TIXboxLiveEngineSignInFailed";

NSString * const kTIXboxLiveEngineWrongEmailOrPassword = @"The email address or password you provided is incorrect.";
NSString * const kTIXboxLiveEngineSiteCannotBeContacted = @"The Xbox LIVE site is all full of errors. Try again later.";
NSString * const kTIXboxLiveEngineTermsOfUseChanged = @"The Xbox LIVE terms of use have changed. Please visit Xbox.com to accept them.";
NSString * const kTIXboxLiveEngineFriendRequestErrorMessage = @"Your friend request could not be sent at this time.";
NSString * const kTIXboxLiveEngineMessageSendErrorMessage = @"Your message could not be sent at this time";

@interface TIXboxLiveEngine ()
@property (nonatomic, copy) NSString * email;
@property (nonatomic, copy) NSString * password;
@property (nonatomic, copy) NSString * cookieHash;
@end

@interface TIXboxLiveEngine (Private)
- (void)cancelRunningConnections;
- (void)clearConnectionQueue;
- (void)removeAuthCookies;
- (void)resetCredentials;
- (TIXboxLiveEngineConnection *)getFriendsWithToken:(BOOL)withToken;
- (TIXboxLiveEngineConnection *)getGamesWithToken:(BOOL)withToken;
- (TIXboxLiveEngineConnection *)getRecentPlayersWithToken:(BOOL)withToken;
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type;
- (void)setVerificationTokenFromResponse:(NSString *)response;
- (void)attemptVerificationTokenRecoveryForConnection:(TIXboxLiveEngineConnection *)connection;
- (void)constructAndPostAuthValuesFromResponse:(NSString *)response connectionType:(TIXboxLiveEngineConnectionType)type callback:(id)callback;
- (void)doCallbackForSignOut:(BOOL)userInstigated;
- (void)doCallbackForBasicGamerInfo:(NSDictionary *)gamerInfo connection:(TIXboxLiveEngineConnection *)connection;
- (void)doCallbackForError:(NSError *)error connection:(TIXboxLiveEngineConnection *)connection;
- (void)doCallbackForErrorWithMessage:(NSString *)message code:(NSInteger)code connection:(TIXboxLiveEngineConnection *)connection;
- (void)addConnectionToQueue:(TIXboxLiveEngineConnection *)connection;
- (void)startQueuedConnections;
- (void)addParserToParsers:(id)parser;
- (void)removeParserFromParsers:(id)parser;
- (void)beginMultitaskingForConnection:(TIXboxLiveEngineConnection *)connection;
- (void)endMultitaskingForConnection:(TIXboxLiveEngineConnection *)connection;
- (void)setNetworkSpinnerVisible:(BOOL)visible;
@end

@implementation TIXboxLiveEngine {
	
	NSMutableDictionary * _returnDataDict;
	NSMutableArray * _connectionQueue;
	NSMutableArray * _parsers;
	
	NSString * _verificationToken;
	NSInteger _verificationTokenAttemptCount;
}
@synthesize user = _user;
@synthesize email = _email;
@synthesize password = _password;
@synthesize cookieHash = _cookieHash;
@synthesize signedIn = _signedIn;
@synthesize signingIn = _signingIn;
@synthesize loadingFriends = _loadingFriends;
@synthesize loadingGames = _loadingGames;
@synthesize loadingMessages = _loadingMessages;
@synthesize loadingRecentPlayers = _loadingRecentPlayers;
@synthesize signOutBlock = _signOutBlock;
@synthesize logBlock = _logBlock;

#pragma mark - Init
- (id)init {
	
	if ((self = [super init])){
		
		_signedIn = NO;
		_signingIn = NO;
		_loadingFriends = NO;
		_loadingGames = NO;
		_loadingMessages = NO;
		_loadingRecentPlayers = NO;
		
		_verificationToken = nil;
		_verificationTokenAttemptCount = 0;
		
		_email = nil;
		_password = nil;
		_cookieHash = nil;
		
		_returnDataDict = [[NSMutableDictionary alloc] init];
		_connectionQueue = [[NSMutableArray alloc] init];
		_parsers = [[NSMutableArray alloc] init];
		
		_signOutBlock = nil;
		_logBlock = nil;
	}
	
	return self;
}

#pragma mark - Property Overrides
- (void)setVerificationTokenFromResponse:(NSString *)response {
	_verificationToken = [response stringBetween:@"<input name=\"__RequestVerificationToken\" type=\"hidden\" value=\"" and:@"\""];
}

#pragma mark - Connection / Queue stuff Methods
- (void)cancelRunningConnections {
	
	[_returnDataDict enumerateKeysAndObjectsUsingBlock:^(NSValue * key, id obj, BOOL *stop) {
		[(TIXboxLiveEngineConnection *)key.pointerValue cancel];
		[self setNetworkSpinnerVisible:NO];
	}];
	
	[_returnDataDict removeAllObjects];
	[_parsers removeAllObjects];
}

- (void)clearConnectionQueue {
	[_connectionQueue removeAllObjects];
}

- (void)removeAuthCookies {
	[[TIXboxLiveEngineCookieStorage sharedCookieStorage] removeAllCookiesForHash:_cookieHash];
}

- (void)resetCredentials {
	[self removeAuthCookies];
	[self setEmail:nil];
	[self setPassword:nil];
	[self setCookieHash:nil];
}

#pragma mark - Sign in / out
- (void)signInWithEmail:(NSString *)anEmail password:(NSString *)aPassword callback:(TIXboxLiveEngineConnectionBlock)callback {
	
	if (!_signingIn){
		
		_verificationTokenAttemptCount = 0;
		
		if (_email) [self removeAuthCookies];
		
		[self setEmail:anEmail];
		[self setPassword:aPassword];
		[self setCookieHash:_email.fileSafeHash];
		[self removeAuthCookies];
		
		NSString * loginAddress = @"https://login.live.com/login.srf?wa=wsignin1.0&rpsnv=11&ct=1318941594&rver=6.0.5286.0&wp=MBI&"
		"wreply=https:%2F%2Flive.xbox.com:443%2Fxweb%2Flive%2Fpassport%2FsetCookies.ashx%3Frru%3D"
		"http%253a%252f%252flive.xbox.com%252fen-GB%252fProfile&lc=2057&id=66262&cbcxt=0";
		
		NSURL * loginURL = [NSURL URLWithString:loginAddress];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:loginURL];
		[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetLogin] setCallback:callback];
		
		_signingIn = YES;
	}
}

- (void)signOut {
	
	[self resetCredentials];
	[self clearConnectionQueue];
	[self cancelRunningConnections];
	[self doCallbackForSignOut:YES];
}

#pragma mark - Friends
- (void)getFriendsWithCallback:(TIXboxLiveEngineFriendsBlock)callback {
	
	if (!_loadingFriends){
		_loadingFriends = _signedIn ? YES : NO;
		[[self getFriendsWithToken:(_verificationToken != nil)] setCallback:callback];
	}
}

- (TIXboxLiveEngineConnection *)getFriendsWithToken:(BOOL)withToken {
	
	NSString * friendsAddress = @"https://live.xbox.com/en-GB/Friends/List";
	if (!withToken) friendsAddress = @"https://live.xbox.com/en-GB/Friends";
	
	NSURL * friendsURL = [NSURL URLWithString:friendsAddress];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:friendsURL];
	
	if (withToken){
		
		[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
		[request setValue:@"https://live.xbox.com/en-GB/Friends" forHTTPHeaderField:@"Referer"];
		
		TIURLRequestParameter * requestParam = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:_verificationToken];
		[request setParameters:[NSArray arrayWithObject:requestParam]];
	}
	
	TIXboxLiveEngineConnectionType type = TIXboxLiveEngineConnectionTypeGetFriends;
	if (!withToken) type = TIXboxLiveEngineConnectionTypeGetFriendsVerification;
	
	return [self connectionWithRequest:request type:type];
}

- (void)getRecentPlayersWithCallback:(TIXboxLiveEngineRecentPlayersBlock)callback {
	
	if (!_loadingRecentPlayers){
		_loadingRecentPlayers = _signedIn ? YES : NO;
		[[self getRecentPlayersWithToken:(_verificationToken != nil)] setCallback:callback];
	}
}

- (TIXboxLiveEngineConnection *)getRecentPlayersWithToken:(BOOL)withToken {
	
	NSString * playersAddress = @"https://live.xbox.com/en-GB/Friends/Recent";
	if (!withToken) playersAddress = @"https://live.xbox.com/en-GB/Friends";
	
	NSURL * playersURL = [NSURL URLWithString:playersAddress];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:playersURL];
	
	if (withToken){
		
		[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
		[request setValue:@"https://live.xbox.com/en-GB/Friends" forHTTPHeaderField:@"Referer"];
		
		TIURLRequestParameter * requestParam = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:_verificationToken];
		[request setParameters:[NSArray arrayWithObject:requestParam]];
	}
	
	TIXboxLiveEngineConnectionType type = TIXboxLiveEngineConnectionTypeGetRecentPlayers;
	if (!withToken) type = TIXboxLiveEngineConnectionTypeGetRecentPlayersVerification;
	
	return [self connectionWithRequest:request type:type];
}

- (void)getFriendsOfFriend:(NSString *)gamertag callback:(TIXboxLiveEngineFriendsOfFriendBlock)callback {
	
	if (gamertag.isNotEmpty){
		
		NSURL * friendsURL = [NSURL URLWithString:@"https://live.xbox.com/en-GB/Friends/List"];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:friendsURL];
		
		[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
		[request setValue:[@"https://live.xbox.com/en-GB/Friends?gamertag="
						   stringByAppendingString:[gamertag.stringByTrimmingWhitespaceAndNewLines stringByReplacingOccurrencesOfString:@" " withString:@"+"]]
	   forHTTPHeaderField:@"Referer"];
		
		TIURLRequestParameter * gamertagParam = [[TIURLRequestParameter alloc] initWithName:@"gamertag" value:gamertag];
		TIURLRequestParameter * verificationParam = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:_verificationToken];
		[request setParameters:[NSArray arrayWithObjects:gamertagParam, verificationParam, nil]];
		
		TIXboxLiveEngineConnection * connection = [self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetFriendsOfFriend];
		[connection setUserInfo:[NSDictionary dictionaryWithObject:gamertag forKey:TIXboxLiveEngineConnectionGamertagKey]];
		[connection setCallback:callback];
	}
}

- (void)sendFriendRequestToGamer:(NSString *)gamertag callback:(TIXboxLiveEngineFriendRequestBlock)callback {
	
	if (gamertag.isNotEmpty){
		
		NSURL * friendRequestURL = [NSURL URLWithString:@"https://live.xbox.com/en-GB/Friends/Add"];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:friendRequestURL];
		
		[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
		
		TIURLRequestParameter * parameter = [[TIURLRequestParameter alloc] initWithName:@"gamertag" value:gamertag.stringByTrimmingWhitespaceAndNewLines];
		TIURLRequestParameter * parameter2 = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:_verificationToken];
		[request setParameters:[NSArray arrayWithObjects:parameter, parameter2, nil]];
		
		TIXboxLiveEngineConnection * connection = [self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeSendFriendRequest];
		[connection setUserInfo:[NSDictionary dictionaryWithObject:gamertag forKey:TIXboxLiveEngineConnectionGamertagKey]];
		[connection setCallback:callback];
	}
}

#pragma mark - Games
- (void)getGamesWithCallback:(TIXboxLiveEngineGamesBlock)callback {
	
	if (!_loadingGames){
		_loadingGames = _signedIn ? YES : NO;
		[[self getGamesWithToken:(_verificationToken != nil)] setCallback:callback];
	}
}

- (TIXboxLiveEngineConnection *)getGamesWithToken:(BOOL)withToken {
	
	NSString * gamesAddress = @"https://live.xbox.com/en-GB/Activity/Summary";
	if (!withToken) gamesAddress = @"https://live.xbox.com/en-GB/Activity";
	
	NSURL * gamesURL = [NSURL URLWithString:gamesAddress];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:gamesURL];
	
	if (withToken){
		
		[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
		[request setValue:@"https://live.xbox.com/en-GB/Activity" forHTTPHeaderField:@"Referer"];
		
		TIURLRequestParameter * requestParam = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:_verificationToken];
		[request setParameters:[NSArray arrayWithObject:requestParam]];
	}
	
	TIXboxLiveEngineConnectionType type = TIXboxLiveEngineConnectionTypeGetGames;
	if (!withToken) type = TIXboxLiveEngineConnectionTypeGetGamesVerification;
	
	return [self connectionWithRequest:request type:type];
}

- (void)getAchievementsForGame:(TIXboxLiveGame *)game callback:(TIXboxLiveEngineAchievementsBlock)callback {
	
	if (game){
		
		NSString * achievementsAddress = [NSString stringWithFormat:@"https://live.xbox.com/en-GB/Activity/Details?titleId=%@", game.titleID];
		NSURL * achievementsURL = [NSURL URLWithString:achievementsAddress];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:achievementsURL];
		
		TIXboxLiveEngineConnection * connection = [self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetAchievements];
		[connection setUserInfo:[NSDictionary dictionaryWithObject:game forKey:TIXboxLiveEngineConnectionGameKey]];
		[connection setCallback:callback];
	}
}

- (void)getGamesComparedWithGamer:(NSString *)gamertag callback:(TIXboxLiveEngineGamesBlock)callback {
	
	if (gamertag.isNotEmpty){
		
		NSString * gamesAddress = [NSString stringWithFormat:@"https://live.xbox.com/en-GB/Activity/Summary?CompareTo=%@",
								   [[gamertag stringByTrimmingWhitespaceAndNewLines] stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
		NSURL * gamesURL = [NSURL URLWithString:gamesAddress];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:gamesURL];
		
		[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
		[request setValue:@"https://live.xbox.com/en-GB/Activity" forHTTPHeaderField:@"Referer"];
		
		TIURLRequestParameter * requestParam = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:_verificationToken];
		[request setParameters:[NSArray arrayWithObject:requestParam]];
		
		TIXboxLiveEngineConnection * connection = [self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetGameComparisons];
		[connection setUserInfo:[NSDictionary dictionaryWithObject:gamertag forKey:TIXboxLiveEngineConnectionGamertagKey]];
		[connection setCallback:callback];
	}
}

- (void)getAchievementsComparisonsForGame:(TIXboxLiveGame *)game callback:(TIXboxLiveEngineAchievementsBlock)callback {
	
	if (game){
		NSString * achievementsAddress = [NSString stringWithFormat:@"https://live.xbox.com/en-GB/Activity/Details?titleId=%@&compareTo=%@",
										  game.titleID, game.gamertagComparedWith.encodedURLString];
		NSURL * achievementsURL = [NSURL URLWithString:achievementsAddress];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:achievementsURL];
		
		TIXboxLiveEngineConnection * connection = [self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetAchievementComparisons];
		[connection setUserInfo:[NSDictionary dictionaryWithObject:game forKey:TIXboxLiveEngineConnectionGameKey]];
		[connection setCallback:callback];
	}
}

#pragma mark - Messages
- (void)getMessagesWithCallback:(TIXboxLiveEngineMessagesBlock)callback {
	
	if (!_loadingMessages){
		_loadingMessages = _signedIn ? YES : NO;
		
		NSURL * messagesURL = [NSURL URLWithString:@"https://live.xbox.com/en-GB/Messages"];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:messagesURL];
		[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetMessages] setCallback:callback];
	}
}

- (void)sendMessage:(NSString *)message recipients:(NSArray *)recipients callback:(TIXboxLiveEngineMessageSentBlock)callback {
	
	if (message.isNotEmpty && recipients){
		
		NSURL * messageURL = [NSURL URLWithString:@"https://live.xbox.com/en-GB/Messages/SendMessage"];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:messageURL];
		
		[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
		
		NSMutableArray * parameters = [NSMutableArray array];
		[recipients enumerateObjectsUsingBlock:^(NSString * recipient, NSUInteger idx, BOOL *stop){
			TIURLRequestParameter * recipientParameter = [[TIURLRequestParameter alloc] initWithName:@"Recipients" value:recipient];
			[parameters addObject:recipientParameter];
		}];
		
		TIURLRequestParameter * messageParameter = [[TIURLRequestParameter alloc] initWithName:@"Message" value:message];
		[parameters addObject:messageParameter];
		
		TIURLRequestParameter * verificationParameter = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:_verificationToken];
		[parameters addObject:verificationParameter];
		
		[request setParameters:parameters];
		
		TIXboxLiveEngineConnection * connection = [self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeSendMessage];
		[connection setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, TIXboxLiveEngineConnectionMessageKey,
								 recipients, TIXboxLiveEngineConnectionRecipientsKey, nil]];
		[connection setCallback:callback];
	}
}

#pragma mark - Delegates
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	
	if (TIXboxLiveEngineConnectionTypeIsFriends(xboxConnection.type)) _loadingFriends = NO;
	if (TIXboxLiveEngineConnectionTypeIsGames(xboxConnection.type)) _loadingGames = NO;
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessages) _loadingMessages = NO;
	if (TIXboxLiveEngineConnectionTypeIsRecentPlayers(xboxConnection.type)) _loadingRecentPlayers = NO;
	if (TIXboxLiveEngineConnectionTypeIsLogin(xboxConnection.type)) _signingIn = NO;
	
	if (_logBlock) _logBlock(xboxConnection, [NSString stringWithFormat:@"Error (%d) - %@", (int)error.code, error.localizedDescription]);
	
	[self doCallbackForError:error connection:xboxConnection];
	[_returnDataDict removeObjectForKey:[NSValue valueWithNonretainedObject:connection]];
	
	[self setNetworkSpinnerVisible:NO];
	[self endMultitaskingForConnection:xboxConnection];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	
	[[TIXboxLiveEngineCookieStorage sharedCookieStorage] addCookiesFromResponse:redirectResponse hash:_cookieHash];
	
	NSMutableURLRequest * newRequest = [request mutableCopy];
	[newRequest setDefaultsForHash:_cookieHash];
	return newRequest;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	[[TIXboxLiveEngineCookieStorage sharedCookieStorage] addCookiesFromResponse:response hash:_cookieHash];
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	id connectionKey = [NSValue valueWithNonretainedObject:connection];
	NSString * response = [[NSString alloc] initWithData:[_returnDataDict objectForKey:connectionKey] encoding:NSUTF8StringEncoding];
	[_returnDataDict removeObjectForKey:connectionKey];
	
	[self setNetworkSpinnerVisible:NO];
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	if (_logBlock) _logBlock(xboxConnection, response);
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetLogin){
		
		TIURLRequestParameter * emailParam = [[TIURLRequestParameter alloc] initWithName:@"login" value:_email];
		TIURLRequestParameter * passwordParam = [[TIURLRequestParameter alloc] initWithName:@"passwd" value:_password];
		TIURLRequestParameter * optionsParam = [[TIURLRequestParameter alloc] initWithName:@"LoginOptions" value:@"1"];
		
		NSMutableArray * parameters = [NSMutableArray arrayWithObjects:emailParam, passwordParam, optionsParam, nil];
		
		NSArray * rawParams = [response componentsSeparatedByString:@"<input type=\"hidden\""];
		for (int i = 1; i < rawParams.count; i++){
			
			NSString * rawParam = [rawParams objectAtIndex:i];
			NSString * name = [rawParam stringBetween:@"name=\"" and:@"\""];
			NSString * value = [rawParam stringBetween:@"value=\"" and:@"\""];
			
			TIURLRequestParameter * parameter = [[TIURLRequestParameter alloc] initWithName:name value:value];
			[parameters addObject:parameter];
		}
		
		NSURL * postURL = [NSURL URLWithString:[response stringBetween:@"urlPost:'" and:@"'"]];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:postURL];
		[request setParameters:parameters];
		
		[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypePostLogin] setCallback:xboxConnection.callback];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypePostLogin){
		
		if ([response contains:kTIXboxLiveEngineJavascriptCheck]){
			[self constructAndPostAuthValuesFromResponse:response connectionType:TIXboxLiveEngineConnectionTypePostAuth callback:xboxConnection.callback];
		}
		else
		{
			[self doCallbackForErrorWithMessage:kTIXboxLiveEngineWrongEmailOrPassword code:TIXboxLiveEngineErrorCodeIncorrectEmailPassword connection:xboxConnection];
		}
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypePostAuth){
		
		if ([response contains:kTIXboxLiveEngineJavascriptCheck]){
			[self constructAndPostAuthValuesFromResponse:response connectionType:TIXboxLiveEngineConnectionTypePostAuth callback:xboxConnection.callback];
		}
		else if (!response.isNotEmpty || [response contains:@"srf_uPost"]){
			[self doCallbackForSignOut:NO];
		}
		else if ([response contains:@"Error - Xbox.com"]){
			[self doCallbackForErrorWithMessage:kTIXboxLiveEngineSiteCannotBeContacted code:TIXboxLiveEngineErrorCodeSiteDown connection:xboxConnection];
		}
		else if ([response contains:@"Updated Terms of Use"]){
			[self doCallbackForErrorWithMessage:kTIXboxLiveEngineTermsOfUseChanged code:TIXboxLiveEngineErrorCodeTermsOfUse connection:xboxConnection];
		}
		else
		{
			dispatch_async_serial("com.TIXboxLiveEngine.ProfileParseQueue", ^{
				[self setVerificationTokenFromResponse:response];
				
				NSString * gamertag = [response stringBetween:@"data-gamertag=\"" and:@"\""];
				NSString * gamerscore = [response stringBetween:@"<div class=\"Gamerscore\">" and:@"</div>"];
				NSString * gamerpic = [response stringBetween:@"<img class=\"gamerpic\" src=\"" and:@"\""];
				gamerpic = [gamerpic stringByReplacingOccurrencesOfString:@"avatarpic-s" withString:@"avatarpic-l"];
				gamerpic = [gamerpic stringByReplacingOccurrencesOfString:@"tile/0/1" withString:@"tile/0/2"];
				
				NSDictionary * gamerInfo = [NSDictionary dictionaryWithObjectsAndKeys:gamertag, @"gamertag", gamerpic, @"gamerpic", gamerscore, @"gamerscore", nil];
				dispatch_async_main_queue(^{[self doCallbackForBasicGamerInfo:gamerInfo connection:xboxConnection];});
			});
		}
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetFriendsVerification){
		
		if ([response contains:kTIXboxLiveEngineJavascriptCheck]){
			[self doCallbackForSignOut:NO];
		}
		else
		{
			[self setVerificationTokenFromResponse:response];
			[[self getFriendsWithToken:YES] setCallback:xboxConnection.callback];
		}
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetFriends){
		
		_loadingFriends = NO;
		
		if ([response contains:@"grid-18 NotFound"] || [response isEqualToString:@"{\"Success\":false}"]){
			[self attemptVerificationTokenRecoveryForConnection:xboxConnection];
		}
		else if (response.isNotEmpty && ![response contains:kTIXboxLiveEngineJavascriptCheck]){
			
			__weak TIXboxLiveEngine * weakSelf = self;
			TIXboxLiveFriendsParser * friendsParser = [[TIXboxLiveFriendsParser alloc] init];
			[friendsParser setVerificationToken:_verificationToken];
			[friendsParser setCookieHash:_cookieHash];
			[friendsParser parseFriendsPage:response callback:^(NSArray *onlineFriends, NSArray *offlineFriends, NSArray * friendRequests) {
				[weakSelf removeParserFromParsers:friendsParser];
				
				TIXboxLiveEngineFriendsBlock friendsBlock = xboxConnection.callback;
				if (friendsBlock) friendsBlock(nil, onlineFriends, offlineFriends, friendRequests);
			}];
			[self addParserToParsers:friendsParser];
		}
		else [self doCallbackForSignOut:NO];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetRecentPlayersVerification){
		
		if (![response contains:kTIXboxLiveEngineJavascriptCheck]){
			[self setVerificationTokenFromResponse:response];
			[[self getRecentPlayersWithToken:YES] setCallback:xboxConnection.callback];
		} else [self doCallbackForSignOut:NO];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetRecentPlayers){
		
		_loadingRecentPlayers = NO;
		
		if ([response contains:@"grid-18 NotFound"] || [response isEqualToString:@"{\"Success\":false}"]){
			[self attemptVerificationTokenRecoveryForConnection:xboxConnection];
		}
		else
		{
			__weak TIXboxLiveEngine * weakSelf = self;
			TIXboxLiveFriendsParser * friendsParser = [[TIXboxLiveFriendsParser alloc] init];
			[friendsParser setVerificationToken:_verificationToken];
			[friendsParser setCookieHash:_cookieHash];
			[friendsParser parseRecentPlayersPage:response callback:^(NSArray * players) {
				[weakSelf removeParserFromParsers:friendsParser];
				
				TIXboxLiveEngineRecentPlayersBlock recentPlayersBlock = xboxConnection.callback;
				if (recentPlayersBlock) recentPlayersBlock(nil, players);
			}];
			[self addParserToParsers:friendsParser];
		}
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetFriendsOfFriend){
		
		__weak TIXboxLiveEngine * weakSelf = self;
		TIXboxLiveFriendsParser * friendsParser = [[TIXboxLiveFriendsParser alloc] init];
		[friendsParser setVerificationToken:_verificationToken];
		[friendsParser setCookieHash:_cookieHash];
		[friendsParser parseFriendsOfFriendPage:response callback:^(NSArray * friends) {
			[weakSelf removeParserFromParsers:friendsParser];
			
			TIXboxLiveEngineFriendsOfFriendBlock friendsBlock = xboxConnection.callback;
			if (friendsBlock) friendsBlock(nil, [xboxConnection.userInfo objectForKey:TIXboxLiveEngineConnectionGamertagKey], friends);
		}];
		[self addParserToParsers:friendsParser];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetGamesVerification){
		
		if (![response contains:kTIXboxLiveEngineJavascriptCheck]){
			[self setVerificationTokenFromResponse:response];
			[[self getGamesWithToken:YES] setCallback:xboxConnection.callback];
		} else [self doCallbackForSignOut:NO];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetGames){
		_loadingGames = NO;
		
		if ([response contains:@"grid-18 NotFound"]){
			[self attemptVerificationTokenRecoveryForConnection:xboxConnection];
		}
		else
		{
			__weak TIXboxLiveEngine * weakSelf = self;
			TIXboxLiveGamesParser * gamesParser = [[TIXboxLiveGamesParser alloc] init];
			[gamesParser parseGamesPage:response callback:^(NSArray * games) {
				[weakSelf removeParserFromParsers:gamesParser];
				
				TIXboxLiveEngineGamesBlock gamesBlock = xboxConnection.callback;
				if (gamesBlock) gamesBlock(nil, nil, games);
			}];
			[self addParserToParsers:gamesParser];
		}
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetGameComparisons){
		
		__weak TIXboxLiveEngine * weakSelf = self;
		TIXboxLiveGamesParser * gamesParser = [[TIXboxLiveGamesParser alloc] init];
		[gamesParser parseGameComparisonsPage:response callback:^(NSArray * games) {
			[weakSelf removeParserFromParsers:gamesParser];
			
			TIXboxLiveEngineGamesBlock gamesBlock = xboxConnection.callback;
			if (gamesBlock) gamesBlock(nil, [xboxConnection.userInfo objectForKey:TIXboxLiveEngineConnectionGamertagKey], games);
		}];
		[self addParserToParsers:gamesParser];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetAchievements){
		
		__weak TIXboxLiveEngine * weakSelf = self;
		TIXboxLiveAchievementsParser * achievementsParser = [[TIXboxLiveAchievementsParser alloc] init];
		[achievementsParser parseAchievementsPage:response callback:^(NSArray * achievements) {
			[weakSelf removeParserFromParsers:achievementsParser];
			
			TIXboxLiveEngineAchievementsBlock block = xboxConnection.callback;
			block(nil, [xboxConnection.userInfo objectForKey:TIXboxLiveEngineConnectionGameKey], achievements);
		}];
		[self addParserToParsers:achievementsParser];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetAchievementComparisons){
		
		__weak TIXboxLiveEngine * weakSelf = self;
		TIXboxLiveAchievementsParser * achievementsParser = [[TIXboxLiveAchievementsParser alloc] init];
		[achievementsParser parseAchievementComparisonsPage:response callback:^(NSArray *achievements) {
			[weakSelf removeParserFromParsers:achievementsParser];
			
			TIXboxLiveEngineAchievementsBlock block = xboxConnection.callback;
			block(nil, [xboxConnection.userInfo objectForKey:TIXboxLiveEngineConnectionGameKey], achievements);
		}];
		[self addParserToParsers:achievementsParser];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessages){
		
		_loadingMessages = NO;
		
		__weak TIXboxLiveEngine * weakSelf = self;
		TIXboxLiveMessagesParser * messagesParser = [[TIXboxLiveMessagesParser alloc] init];
		[messagesParser setCookieHash:_cookieHash];
		[messagesParser setVerificationToken:_verificationToken];
		[messagesParser parseMessagesPage:response callback:^(NSArray * messages) {
			[weakSelf removeParserFromParsers:messagesParser];
			
			TIXboxLiveEngineMessagesBlock messagesBlock = xboxConnection.callback;
			if (messagesBlock) messagesBlock(nil, messages);
		}];
		[self addParserToParsers:messagesParser];
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeSendFriendRequest){
		
		NSDictionary * responseDict = [response objectFromJSONString];
		NSError * error = nil;
		
		if (![[responseDict objectForKey:@"Success"] boolValue]){
			NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:kTIXboxLiveEngineFriendRequestErrorMessage, NSLocalizedDescriptionKey, nil];
			error = [NSError errorWithDomain:kTIXboxLiveEngineErrorDomain code:TIXboxLiveEngineErrorCodeUnknownError userInfo:userInfo];
		}
		
		TIXboxLiveEngineFriendRequestBlock friendRequestBlock = xboxConnection.callback;
		if (friendRequestBlock) friendRequestBlock(error, [xboxConnection.userInfo objectForKey:TIXboxLiveEngineConnectionGamertagKey]);
	}
	
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeSendMessage){
		
		NSDictionary * responseDict = [response objectFromJSONString];
		NSError * error = nil;
		
		if (![[responseDict objectForKey:@"Success"] boolValue]){
			
			NSString * status = [responseDict objectForKey:@"Status"];
			if (!status) status = kTIXboxLiveEngineMessageSendErrorMessage;
			
			NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:status, NSLocalizedDescriptionKey, nil];
			error = [NSError errorWithDomain:kTIXboxLiveEngineErrorDomain code:TIXboxLiveEngineErrorCodeMessageSendingError userInfo:userInfo];
		}
		
		TIXboxLiveEngineMessageSentBlock messageSentBlock = xboxConnection.callback;
		if (messageSentBlock) messageSentBlock(error, [xboxConnection.userInfo objectForKey:TIXboxLiveEngineConnectionRecipientsKey]);
	}
	
	[self endMultitaskingForConnection:xboxConnection];
}

#pragma mark - Private Methods
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type {
	
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
	[request setDefaultsForHash:_cookieHash];
	
	BOOL startImmediately = (TIXboxLiveEngineConnectionTypeIsLogin(type) || _signedIn);
	
	TIXboxLiveEngineConnection * connection = [[TIXboxLiveEngineConnection alloc] initWithRequest:request delegate:self startImmediately:startImmediately];
	if (connection){
		
		[connection setType:type];
		
		[_returnDataDict setObject:[NSMutableData data] forKey:[NSValue valueWithNonretainedObject:connection]];
		
		if (startImmediately){
			[self beginMultitaskingForConnection:connection];
			[self setNetworkSpinnerVisible:YES];
		} else [self addConnectionToQueue:connection];
	}
	
	return connection;
}

- (void)constructAndPostAuthValuesFromResponse:(NSString *)response connectionType:(TIXboxLiveEngineConnectionType)type callback:(id)callback {
	
	if (![response contains:@"history.go(-1)"]){
		
		NSMutableArray * parameters = [[NSMutableArray alloc] init];
		NSArray * rawParams = [response componentsSeparatedByString:@"<input type=\"hidden\""];
		
		[rawParams enumerateObjectsUsingBlock:^(NSString * rawParam, NSUInteger idx, BOOL *stop){
			
			NSString * name = [rawParam stringBetween:@"name=\"" and:@"\""];
			NSString * value = [rawParam stringBetween:@"value=\"" and:@"\""];
			
			if (name.isNotEmpty && value.isNotEmpty){
				TIURLRequestParameter * parameter = [[TIURLRequestParameter alloc] initWithName:name value:value];
				[parameters addObject:parameter];
			}
		}];
		
		NSString * postAddress = [response stringBetween:@"action=\"" and:@"\""];		
		NSURL * postURL = [NSURL URLWithString:postAddress];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:postURL];
		[request setParameters:parameters];
		
		[[self connectionWithRequest:request type:type] setCallback:callback];
	}
	else
	{
		_signingIn = NO;
		[self signInWithEmail:_email password:_password callback:callback];
	}
}

- (void)attemptVerificationTokenRecoveryForConnection:(TIXboxLiveEngineConnection *)connection {
	
	if (_verificationTokenAttemptCount < 3){
		_verificationTokenAttemptCount++;
		
		if (connection.type == TIXboxLiveEngineConnectionTypeGetGames) [[self getGamesWithToken:NO] setCallback:connection.callback];
		else if (connection.type == TIXboxLiveEngineConnectionTypeGetRecentPlayers) [[self getRecentPlayersWithToken:NO] setCallback:connection.callback];
		else if (connection.type == TIXboxLiveEngineConnectionTypeGetFriends) [[self getFriendsWithToken:NO] setCallback:connection.callback];
	}
	else
	{
		[self doCallbackForErrorWithMessage:kTIXboxLiveEngineSiteCannotBeContacted code:TIXboxLiveEngineErrorCodeSiteDown connection:connection];
		_verificationTokenAttemptCount = 0;
	}
}

- (void)doCallbackForSignOut:(BOOL)userInstigated {
	
	_signedIn = NO;
	_signingIn = NO;
	
	if (_signOutBlock) _signOutBlock(userInstigated);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TIXboxLiveEngineDidSignOutNotificationName object:nil];
}

- (void)doCallbackForBasicGamerInfo:(NSDictionary *)gamerInfo connection:(TIXboxLiveEngineConnection *)connection {
	
	_signingIn = NO;
	
	NSString * gamertag = [gamerInfo objectForKey:@"gamertag"];
	if (gamertag.isNotEmpty){
		
		_signedIn = YES;
		[self startQueuedConnections];
		
		NSURL * gamerpicURL = [NSURL URLWithString:[gamerInfo objectForKey:@"gamerpic"]];
		TIXboxLiveUser * newUser = [[TIXboxLiveUser alloc] initWithGamertag:gamertag
																 gamerscore:[gamerInfo objectForKey:@"gamerscore"] 
																	tileURL:gamerpicURL];
		
		[newUser setCookieHash:_cookieHash];
		[newUser getGamerProfileWithCallback:nil];
		[self setUser:newUser];
		
		TIXboxLiveEngineConnectionBlock signInBlock = connection.callback;
		if (signInBlock) signInBlock(nil);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TIXboxLiveEngineDidSignInNotificationName object:nil];
	}
	else
	{
		[self doCallbackForErrorWithMessage:kTIXboxLiveEngineUnknownErrorMessage code:TIXboxLiveEngineErrorCodeUnknownError connection:connection];
	}
}

- (void)doCallbackForErrorWithMessage:(NSString *)message code:(NSInteger)code connection:(TIXboxLiveEngineConnection *)connection {
	
	if (!message) message = kTIXboxLiveEngineUnknownErrorMessage;
	
	NSDictionary * errorDict = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
	NSError * error = [NSError errorWithDomain:kTIXboxLiveEngineErrorDomain code:code userInfo:errorDict];
	
	if (TIXboxLiveEngineConnectionTypeIsLogin(connection.type)){
		_signingIn = NO;
		[self resetCredentials];
		[[NSNotificationCenter defaultCenter] postNotificationName:TIXboxLiveEngineSignInFailedNotificationName object:error];
	}
	
	[self doCallbackForError:error connection:connection];
}

- (void)doCallbackForError:(NSError *)error connection:(TIXboxLiveEngineConnection *)connection {
	
	if (error && connection.callback){
		
		if (TIXboxLiveEngineConnectionTypeIsLogin(connection.type)){
			TIXboxLiveEngineConnectionBlock block = connection.callback;
			block(error);
		}
		else if (TIXboxLiveEngineConnectionTypeIsFriends(connection.type)){
			TIXboxLiveEngineFriendsBlock block = connection.callback;
			block(error, nil, nil, nil);
		}
		else if (TIXboxLiveEngineConnectionTypeIsGames(connection.type) || connection.type == TIXboxLiveEngineConnectionTypeGetGameComparisons){
			TIXboxLiveEngineGamesBlock block = connection.callback;
			block(error, nil, nil);
		}
		else if (TIXboxLiveEngineConnectionTypeIsRecentPlayers(connection.type)){
			TIXboxLiveEngineRecentPlayersBlock block = connection.callback;
			block(error, nil);
		}
		else if (connection.type == TIXboxLiveEngineConnectionTypeGetMessages){
			TIXboxLiveEngineMessagesBlock block = connection.callback;
			block(error, nil);
		}
		else if (connection.type == TIXboxLiveEngineConnectionTypeGetAchievements || connection.type == TIXboxLiveEngineConnectionTypeGetAchievementComparisons){
			TIXboxLiveEngineAchievementsBlock block = connection.callback;
			block(error, nil, nil);
		}
		else if (connection.type == TIXboxLiveEngineConnectionTypeSendFriendRequest){
			TIXboxLiveEngineFriendRequestBlock block = connection.callback;
			block(error, nil);
		}
		else if (connection.type == TIXboxLiveEngineConnectionTypeSendMessage){
			TIXboxLiveEngineMessageSentBlock block = connection.callback;
			block(error, nil);
		}
		else if (connection.type == TIXboxLiveEngineConnectionTypeGetFriendsOfFriend){
			TIXboxLiveEngineFriendsOfFriendBlock block = connection.callback;
			block(error, nil, nil);
		}
	}
}

- (void)addConnectionToQueue:(TIXboxLiveEngineConnection *)connection {
	
	__block BOOL shouldAdd = YES;
	
	if (TIXboxLiveEngineConnectionTypeIsPrimaryGet(connection.type)){
		[_connectionQueue enumerateObjectsUsingBlock:^(TIXboxLiveEngineConnection * checker, NSUInteger idx, BOOL *stop){
			if (checker.type == connection.type){
				shouldAdd = NO;
				*stop = YES;
			}
		}];
	}
	
	if (shouldAdd) [_connectionQueue addObject:connection];
}

- (void)startQueuedConnections {
	
	if (_signedIn){
		
		[_connectionQueue enumerateObjectsUsingBlock:^(TIXboxLiveEngineConnection * connection, NSUInteger idx, BOOL *stop){
			
			[self beginMultitaskingForConnection:connection];
			[connection start];
			
			[self setNetworkSpinnerVisible:YES];
			
			if (connection.type == TIXboxLiveEngineConnectionTypeGetFriends) _loadingFriends = YES;
			if (connection.type == TIXboxLiveEngineConnectionTypeGetMessages) _loadingMessages = YES;
			if (connection.type == TIXboxLiveEngineConnectionTypeGetGames) _loadingGames = YES;
			if (connection.type == TIXboxLiveEngineConnectionTypeGetRecentPlayers) _loadingRecentPlayers = YES;
		}];
		
		[self clearConnectionQueue];
	}
}

- (void)addParserToParsers:(id)parser {
	[_parsers addObject:parser];
	[self setNetworkSpinnerVisible:YES];
}

- (void)removeParserFromParsers:(id)parser {
	[_parsers removeObject:parser];
	[self setNetworkSpinnerVisible:NO];
}

- (void)beginMultitaskingForConnection:(TIXboxLiveEngineConnection *)connection {
#if TARGET_OS_IPHONE
	if ([[UIDevice currentDevice] isMultitaskingSupported]){
		
		UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[self endMultitaskingForConnection:connection];
		}];
		
		[connection setBackgroundTaskIdentifier:[NSNumber numberWithInteger:identifier]];
	}
#endif
}

- (void)endMultitaskingForConnection:(TIXboxLiveEngineConnection *)connection {
#if TARGET_OS_IPHONE
	if ([[UIDevice currentDevice] isMultitaskingSupported]){
		[[UIApplication sharedApplication] endBackgroundTask:connection.backgroundTaskIdentifier.integerValue];
	}
#endif
}

- (void)setNetworkSpinnerVisible:(BOOL)visible {
#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] smartSetNetworkActivityIndicatorVisible:visible];
#endif
}

#pragma mark - Memory Management
- (void)dealloc {
	[self cancelRunningConnections];
	[self resetCredentials];
}

@end