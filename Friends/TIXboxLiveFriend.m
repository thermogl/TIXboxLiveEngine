//
//  TIXboxLiveFriend.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveFriend.h"
#import "TIURLRequestParameter.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIXboxLiveEngineConnection.h"
#import "TIXboxLiveMessage.h"
#import "TIXboxLiveUser.h"

@interface TIXboxLiveFriend (Private)
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type;
- (NSURLConnection *)postConnectionWithAddress:(NSString *)address;
- (void)parseGamerInfo:(NSString *)gamerPage connection:(TIXboxLiveEngineConnection *)connection;
- (void)notifyDelegateOfGamerInfo:(NSDictionary *)gamerInfo forConnection:(TIXboxLiveEngineConnection *)connection;
@end

@implementation TIXboxLiveFriend {	
	NSMutableDictionary * _returnDataDict;
}
@synthesize gamertag = _gamertag;
@synthesize info = _info;
@synthesize status = _status;
@synthesize avatarURL = _avatarURL;
@synthesize isOnFriendsList = _isOnFriendsList;
@synthesize friendRequestType = _friendRequestType;
@synthesize tileURL = _tileURL;

#pragma mark - Init / Copy Methods
- (instancetype)init {
	
	if ((self = [super init])){
		_returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (instancetype)initWithGamertag:(NSString *)aGamertag info:(NSString *)someInfo status:(TIXboxLiveFriendStatus)someStatus tileURL:(NSURL *)aURL {
	
	if ((self = [self init])){
		
		_gamertag = [aGamertag copy];
		_info = [someInfo copy];
		_status = someStatus;
		_tileURL = [aURL copy];
		_avatarURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://avatar.xboxlive.com/avatar/%@/avatar-body.png", _gamertag.encodedURLString]];
		_isOnFriendsList = YES;
		_friendRequestType = TIXboxLiveFriendRequestTypeNone;
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		_gamertag = [[aDecoder decodeObjectForKey:@"Gamertag"] copy];
		_info = @"Waiting for refresh";
		_status = TIXboxLiveFriendStatusUnknown;
		_avatarURL = [[aDecoder decodeObjectForKey:@"AvatarURL"] copy];
		_isOnFriendsList = [aDecoder decodeBoolForKey:@"IsOnFriendsList"];
		_friendRequestType = TIXboxLiveFriendRequestTypeNone;
		_tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] copy];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_gamertag forKey:@"Gamertag"];
	[aCoder encodeBool:_isOnFriendsList forKey:@"IsOnFriendsList"];
	[aCoder encodeObject:_tileURL forKey:@"TileURL"];
	[aCoder encodeObject:_avatarURL forKey:@"AvatarURL"];
}

- (id)copyWithZone:(NSZone *)zone {
	
	TIXboxLiveFriend * friend = [[[self class] allocWithZone:zone] init];
	[friend setGamertag:_gamertag];
	[friend setInfo:_info];
	[friend setStatus:_status];
	[friend setAvatarURL:_avatarURL];
	[friend setIsOnFriendsList:_isOnFriendsList];
	[friend setTileURL:_tileURL];
	
	return friend;
}

- (NSComparisonResult)compare:(TIXboxLiveFriend *)aFriend {
	
	if (_status == aFriend.status){
		return [self statusInsensitiveCompare:aFriend];
	}
	else if (_status == TIXboxLiveFriendStatusRequest){
		return NSOrderedAscending;
	}
	else if (_status == TIXboxLiveFriendStatusOffline){
		return NSOrderedDescending;
	}
	else if (_status == TIXboxLiveFriendStatusOnline){
		if (aFriend.status == TIXboxLiveFriendStatusRequest) return NSOrderedDescending;
		if (aFriend.status == TIXboxLiveFriendStatusOffline) return NSOrderedAscending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)statusInsensitiveCompare:(TIXboxLiveFriend *)aFriend {
	return [_gamertag caseInsensitiveCompare:aFriend.gamertag];
}

+ (TIXboxLiveFriend *)friendWithGamertag:(NSString *)aGamertag {
	
	TIXboxLiveFriend * friend = [[TIXboxLiveFriend alloc] initWithGamertag:aGamertag info:@"Unknown" status:TIXboxLiveFriendStatusUnknown tileURL:nil];
	[friend setIsOnFriendsList:NO];
	return friend;
}

#pragma mark - Connection Methods
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type {
	
	[request setDefaultsForHash:self.cookieHash];
	
	TIXboxLiveEngineConnection * connection = [[TIXboxLiveEngineConnection alloc] initWithRequest:request delegate:self];
	[connection setType:type];
	if (connection) [_returnDataDict setObject:[NSMutableData data] forKey:[NSValue valueWithNonretainedObject:connection]];
	return connection;
}

- (NSURLConnection *)postConnectionWithAddress:(NSString *)address {
	
	NSURL * requestURL = [NSURL URLWithString:address];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:requestURL];
	
	[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
	[request setDefaultsForHash:self.cookieHash];
	
	TIURLRequestParameter * tagParameter = [[TIURLRequestParameter alloc] initWithName:@"gamerTag" value:_gamertag];
	TIURLRequestParameter * verificationParameter = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:self.verificationToken];
	[request setParameters:[NSArray arrayWithObjects:tagParameter, verificationParameter, nil]];
	
	return [NSURLConnection connectionWithRequest:request delegate:nil];
}

- (void)getGamerInfoWithCallback:(TIXboxLiveFriendGamerInfoBlock)callback {
	
	NSString * gamerAddress = [@"https://live.xbox.com/en-GB/MyXbox/Profile?gamertag=" stringByAppendingString:_gamertag.encodedURLParameterString];
	
	NSURL * URL = [NSURL URLWithString:gamerAddress];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:URL];
	
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetFriendGamerInfo] setCallback:callback];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetFriendGamerInfo){
		
		TIXboxLiveFriendGamerInfoBlock infoBlock = xboxConnection.callback;
		if (infoBlock) infoBlock(error, nil, nil, nil, nil, nil, nil);
	}
	
	[_returnDataDict removeObjectForKey:[NSValue valueWithNonretainedObject:connection]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	NSData * returnData = [_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]];
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetFriendGamerInfo){
		NSString * response = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		dispatch_async_serial("com.TIXboxLiveEngine.FriendProfileParseQueue", ^{[self parseGamerInfo:response connection:xboxConnection];});
	}
	
	[_returnDataDict removeObjectForKey:[NSValue valueWithNonretainedObject:connection]];
}

#pragma mark - Helpers
- (void)parseGamerInfo:(NSString *)gamerPage connection:(TIXboxLiveEngineConnection *)connection {
	
	NSString * realName = [gamerPage stringBetween:@"<div class=\"name\" title=\"" and:@"\""];
	NSString * location = [[[gamerPage stringBetween:@"<label>Location:</label>" and:@"</div>"] stringByTrimmingWhitespaceAndNewLines] 
						   stringByReplacingOccurrencesOfString:@"<div class=\"value\">" withString:@""];
	NSString * bio = [gamerPage stringBetween:@"<div class=\"value\" title=\"" and:@"\""];
	
	NSString * motto = [[gamerPage stringBetween:@"<div class=\"motto\">" and:@"<div class=\"bubble-arrow\""] stringByTrimmingWhitespaceAndNewLines];
	
	NSString * gamerscore = [gamerPage stringBetween:@"<div class=\"gamerscore\">" and:@"</div>"];
	NSString * newInfo = [[gamerPage stringBetween:@"<div class=\"presence\">" and:@"</div>"] stringByCorrectingDateRelativeToLocale];
	
	if (!_tileURL) _tileURL = [NSURL URLWithString:[gamerPage stringBetween:@"<img class=\"gamerpic\" src=\"" and:@"\""]];
	
	TIXboxLiveFriendGamerInfoBlock infoBlock = connection.callback;
	if (infoBlock) dispatch_async_main_queue(^{infoBlock(nil, realName, motto, location, bio, gamerscore, newInfo);});
}

#pragma mark - Gamer Methods
- (NSString *)statusDescription {
	
	if (_status == TIXboxLiveFriendStatusOnline) return @"Online";
	else if (_status == TIXboxLiveFriendStatusOffline) return @"Offline";
	else if (_status == TIXboxLiveFriendStatusRequest) return @"Pending";
	else return @"Unknown";
}

- (BOOL)isEqual:(id)object {
	
	if ([object isKindOfClass:[TIXboxLiveMessage class]]){
		return [_gamertag.lowercaseString isEqualToString:((TIXboxLiveMessage *)object).sender.lowercaseString];
	}
	
	if ([object isKindOfClass:[TIXboxLiveFriend class]]) return [self isEqualToFriend:object];
	if ([object isKindOfClass:[TIXboxLiveUser class]]) return [(TIXboxLiveUser *)object isEqualToFriend:self];
	
	return [super isEqual:object];
}

- (BOOL)isEqualToFriend:(TIXboxLiveFriend *)aFriend {
	return (self == aFriend || [self hasGamertag:aFriend.gamertag]);
}

- (BOOL)hasGamertag:(NSString *)aGamertag {
	return [_gamertag.lowercaseString isEqualToString:aGamertag.lowercaseString];
}

- (BOOL)removeFriend {
	
	NSString * removeAddress = @"https://live.xbox.com/en-GB/Friends/Remove";
	
	if (_friendRequestType == TIXboxLiveFriendRequestTypeOutgoing)
		removeAddress = @"https://live.xbox.com/en-GB/Friends/Cancel";
	
	if (_friendRequestType == TIXboxLiveFriendRequestTypeIncoming)
		removeAddress = @"https://live.xbox.com/en-GB/Friends/Decline";
	
	return ([self postConnectionWithAddress:removeAddress] != nil);
}

- (BOOL)handleFriendRequest:(BOOL)shouldAccept {
	
	NSString * requestAddress = @"https://live.xbox.com/en-GB/Friends/Accept";
	if (!shouldAccept) requestAddress = @"https://live.xbox.com/en-GB/Friends/Decline";
	
	return ([self postConnectionWithAddress:requestAddress] != nil);
}

- (NSString *)game {
	
	NSString * game = @"";
	if (_status == TIXboxLiveFriendStatusOnline){
		
		game = [_info stringBetween:@"playing " and:@" -"];
		if (!game.isNotEmpty){
			
			NSRange gameRange = [_info rangeOfString:@"playing "];
			game = [[_info substringFromIndex:(gameRange.location + gameRange.length)] stringByReplacingWeirdEncoding];
		}
	}
	
	return game;
}

- (BOOL)changedGame:(TIXboxLiveFriend *)oldFriend {
	
	if (oldFriend && ![self.game isEqualToString:@""]){
		return (![self.game isEqualToString:oldFriend.game] && 
				oldFriend.status == TIXboxLiveFriendStatusOnline && _status == TIXboxLiveFriendStatusOnline);
	}
	
	return NO;
}

#pragma mark - Other Stuff
- (NSDictionary *)dictRepresentation {
	
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	[dict safelySetObject:_gamertag forKey:@"Gamertag"];
	[dict safelySetObject:_info forKey:@"Info"];
	return dict;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveFriend %p; %@>", self, [self dictRepresentation]];
}

@end