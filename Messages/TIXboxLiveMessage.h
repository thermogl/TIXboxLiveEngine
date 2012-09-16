//
//  TIXboxLiveMessage.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 24/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieBase.h"
#define TIXboxLiveMessageAttachmentIsImage(type) ((type) == TIXboxLiveMessageAttachmentTypeImage || (type) == TIXboxLiveMessageAttachmentTypeBoth)
#define TIXboxLiveMessageAttachmentIsVoice(type) ((type) == TIXboxLiveMessageAttachmentTypeVoice || (type) == TIXboxLiveMessageAttachmentTypeBoth)

typedef enum {
	TIXboxLiveMessageReadStatusRead = 0,
	TIXboxLiveMessageReadStatusUnread = 1,
} TIXboxLiveMessageReadStatus;

typedef enum {
	TIXboxLiveMessageAttachmentTypeNone = 0,
	TIXboxLiveMessageAttachmentTypeImage = 1,
	TIXboxLiveMessageAttachmentTypeVoice = 2,
	TIXboxLiveMessageAttachmentTypeBoth = 3,
} TIXboxLiveMessageAttachmentType;

typedef void (^TIXboxLiveMessageBodyBlock)(NSString * body);
typedef void (^TIXboxLiveMessageImageBlock)(NSString * imagePath);

@interface TIXboxLiveMessage : TIXboxLiveEngineCookieBase <NSCoding> {

	NSString * messageID;
	NSString * sender;
	NSString * summary;
	NSDate * date;
	TIXboxLiveMessageReadStatus readStatus;
	TIXboxLiveMessageAttachmentType attachmentType;
	NSString * body;
	
	NSString * relativeDateStamp;
	NSString * fullDateStamp;
	
	NSMutableDictionary * returnDataDict;
}

@property (nonatomic, copy) NSString * messageID;
@property (nonatomic, copy) NSString * sender;
@property (nonatomic, copy) NSString * summary;
@property (nonatomic, copy) NSDate * date;
@property (nonatomic, assign) TIXboxLiveMessageReadStatus readStatus;
@property (nonatomic, copy) NSString * body;
@property (nonatomic, readonly) TIXboxLiveMessageAttachmentType attachmentType;
@property (nonatomic, copy) NSString * relativeDateStamp;
@property (nonatomic, copy) NSString * fullDateStamp;
@property (nonatomic, readonly) BOOL isFriendRequest;

- (id)initWithMessageID:(NSString *)anID sender:(NSString *)aSender summary:(NSString *)aSummary date:(NSDate *)aDate 
			 readStatus:(TIXboxLiveMessageReadStatus)aStatus attachmentType:(TIXboxLiveMessageAttachmentType)type;

- (BOOL)isEqualToMessage:(TIXboxLiveMessage *)message;
- (BOOL)hasMessageID:(NSString *)anID;
- (BOOL)deleteMessage;
- (BOOL)handleFriendRequest:(BOOL)shouldAccept;

- (void)downloadMessageWithBodyCallback:(TIXboxLiveMessageBodyBlock)bodyCallback imageCallback:(TIXboxLiveMessageImageBlock)imageCallback;

@end
