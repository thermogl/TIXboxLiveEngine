//
//  TIXboxLiveMessage.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 24/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveMessage.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIURLRequestParameter.h"
#import "TIXboxLiveEngineConnection.h"

@interface TIXboxLiveMessage (Private)
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type;
- (void)addParametersToRequest:(NSMutableURLRequest *)request;
@end

@implementation TIXboxLiveMessage {
	NSMutableDictionary * _returnDataDict;
}
@synthesize messageID = _messageID;
@synthesize sender = _sender;
@synthesize summary = _summary;
@synthesize date = _date;
@synthesize readStatus = _readStatus;
@synthesize body = _body;
@synthesize attachmentType = _attachmentType;
@synthesize relativeDateStamp = _relativeDateStamp;
@synthesize fullDateStamp = _fullDateStamp;

- (id)init {
	
	if ((self = [super init])){
		_returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithMessageID:(NSString *)anID sender:(NSString *)aSender summary:(NSString *)aSummary date:(NSDate *)aDate 
			 readStatus:(TIXboxLiveMessageReadStatus)aStatus attachmentType:(TIXboxLiveMessageAttachmentType)type {
	
	if ((self = [self init])){
		
		_messageID = [anID copy];
		_sender = [aSender copy];
		_summary = [aSummary copy];
		_date = [aDate copy];
		_readStatus = aStatus;
		_attachmentType = type;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		_messageID = [[aDecoder decodeObjectForKey:@"MessageID"] copy];
		_sender = [[aDecoder decodeObjectForKey:@"Sender"] copy];
		_summary = [[aDecoder decodeObjectForKey:@"Summary"] copy];
		_date = [[aDecoder decodeObjectForKey:@"Date"] copy];
		_readStatus = [aDecoder decodeIntegerForKey:@"ReadStatus"];
		_body = [[aDecoder decodeObjectForKey:@"Body"] copy];
		_attachmentType = [aDecoder decodeIntegerForKey:@"AttachmentType"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_messageID forKey:@"MessageID"];
	[aCoder encodeObject:_sender forKey:@"Sender"];
	[aCoder encodeObject:_summary forKey:@"Summary"];
	[aCoder encodeObject:_date forKey:@"Date"];
	[aCoder encodeInteger:_readStatus forKey:@"ReadStatus"];
	[aCoder encodeObject:_body forKey:@"Body"];
	[aCoder encodeInteger:_attachmentType forKey:@"AttachmentType"];
}

- (NSString *)relativeDateStamp {
	
	if (!_relativeDateStamp)
		_relativeDateStamp = [_date.relativeDateString retain];
	
	return _relativeDateStamp;
}

- (NSString *)fullDateStamp {
	
	if (!_fullDateStamp)
		_fullDateStamp = [_date.fullDateString retain];
	
	return _fullDateStamp;
}

- (BOOL)isEqual:(id)object {
	
	if ([object isKindOfClass:[TIXboxLiveMessage class]]) 
		return [self isEqualToMessage:object];
	
	return [object isEqual:self];
}

- (BOOL)isEqualToMessage:(TIXboxLiveMessage *)message {
	return (self == message || [self hasMessageID:message.messageID]);
}

- (BOOL)hasMessageID:(NSString *)anID {
	return [_messageID isEqualToString:anID];
}

- (BOOL)isFriendRequest {
	return ([_summary.lowercaseString contains:@"wants to be your friend"]);
}

- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type {
	
	[request setDefaultsForHash:self.cookieHash];
	
	TIXboxLiveEngineConnection * connection = [[TIXboxLiveEngineConnection alloc] initWithRequest:request delegate:self];
	[connection setType:type];
	
	if (connection){
		NSMutableData * data = [[NSMutableData alloc] init];
		[_returnDataDict setObject:data forKey:[NSValue valueWithPointer:connection]];
		[data release];
	}
	
	[connection release];
	return connection;
}

- (void)addParametersToRequest:(NSMutableURLRequest *)request {
	
	NSMutableArray * parameters = [[NSMutableArray alloc] init];
	
	TIURLRequestParameter * parameter = [[TIURLRequestParameter alloc] initWithName:@"msgID" value:_messageID];
	[parameters addObject:parameter];
	[parameter release];
	
	TIURLRequestParameter * parameter2 = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:self.verificationToken];
	[parameters addObject:parameter2];
	[parameter2 release];
	
	[request setParameters:parameters];
	[parameters release];
}

- (BOOL)deleteMessage {
	
	if (self.isFriendRequest) return [self handleFriendRequest:NO];
	
	NSURL * deleteURL = [[NSURL alloc] initWithString:@"https://live.xbox.com/en-GB/Messages/Delete"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:deleteURL];
	[deleteURL release];
	
	[request setDefaultsForHash:self.cookieHash];
	[self addParametersToRequest:request];
	
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
	
	[request release];
	[connection release];
	
	return (connection != nil);
}

- (BOOL)handleFriendRequest:(BOOL)shouldAccept {
	
	NSString * requestAddress = @"https://live.xbox.com/en-GB/Friends/Accept";
	if (!shouldAccept) requestAddress = @"https://live.xbox.com/en-GB/Friends/Decline";
	
	NSURL * requestURL = [[NSURL alloc] initWithString:requestAddress];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
	[requestURL release];
	
	[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
	[request setDefaultsForHash:self.cookieHash];
	
	TIURLRequestParameter * verificationParameter = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:self.verificationToken];
	TIURLRequestParameter * gamertagParameter = [[TIURLRequestParameter alloc] initWithName:@"gamerTag" value:_sender];
	
	NSArray * parameters = [[NSArray alloc] initWithObjects:verificationParameter, gamertagParameter, nil];
	[request setParameters:parameters];
	[parameters release];
	
	[verificationParameter release];
	[gamertagParameter release];
	
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
	
	[request release];
	[connection release];
	
	return (connection != nil);
}

- (void)getMessageWithBodyCallback:(TIXboxLiveMessageBodyBlock)bodyCallback imageCallback:(TIXboxLiveMessageImageBlock)imageCallback {
	
	NSURL * URL = [[NSURL alloc] initWithString:@"https://live.xbox.com/en-GB/Messages/Message"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[URL release];
	
	[request setDefaultsForHash:self.cookieHash];
	[self addParametersToRequest:request];
	
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetMessageBody] setCallback:bodyCallback];
	[request release];
	
	if (_attachmentType == TIXboxLiveMessageAttachmentTypeImage){
		
		NSURL * imageURL = [[NSURL alloc] initWithString:[@"https://live.xbox.com/en-GB/Messages/Image?msgId=" stringByAppendingString:_messageID]];
		NSMutableURLRequest * imageRequest = [[NSMutableURLRequest alloc] initWithURL:imageURL];
		[imageURL release];
		
		[imageRequest setDefaultsForHash:self.cookieHash];
		[[self connectionWithRequest:imageRequest type:TIXboxLiveEngineConnectionTypeGetMessageImage] setCallback:imageCallback];
		[imageRequest release];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessageBody){
		[self setBody:error.localizedDescription];
		
		TIXboxLiveMessageBodyBlock bodyBlock = xboxConnection.callback;
		if (bodyBlock) bodyBlock(_body);
	}
	
	[_returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithPointer:connection]] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithPointer:connection]] setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	NSData * returnData = [_returnDataDict objectForKey:[NSValue valueWithPointer:connection]];
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessageBody){
		
		NSString * response = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];		
		NSDictionary * contentDict = [[response objectFromJSONString] objectForKey:@"Data"];
		[response release];
		
		NSString * tempBody = [contentDict safeObjectForKey:@"Text"];
		
		if (!tempBody.isNotEmpty && TIXboxLiveMessageAttachmentIsVoice(_attachmentType))
			tempBody = @"Voice attachments can only be viewed on your console.";
		
		if (!tempBody) tempBody = @"An error occured when downloading the message";
		
		[self setBody:tempBody.stringByReplacingWeirdEncoding];
		[self setReadStatus:TIXboxLiveMessageReadStatusRead];
		
		TIXboxLiveMessageBodyBlock bodyBlock = xboxConnection.callback;
		if (bodyBlock) bodyBlock(_body);
	}
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessageImage){
#if TARGET_OS_IPHONE
		UIImage * image = [[UIImage alloc] initWithData:returnData];
#else
		NSImage * image = [[NSImage alloc] initWithData:returnData];
#endif
		TIXboxLiveMessageImageBlock imageBlock = xboxConnection.callback;
		if (imageBlock) imageBlock(image);
		
		[image autorelease];
	}
	
	[_returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
}

- (NSComparisonResult)compare:(TIXboxLiveMessage *)message {
	return [_sender caseInsensitiveCompare:message.sender];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveMessage %p; sender = \"%@\"; summary = \"%@\">", self, _sender, _summary];
}

- (void)dealloc {
	[_messageID release];
	[_sender release];
	[_summary release];
	[_date release];
	[_body release];
	[_returnDataDict release];
	[_relativeDateStamp release];
	[_fullDateStamp release];
	[super dealloc];
}

@end