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
#if TARGET_OS_IPHONE
typedef void (^TIXboxLiveMessageImageBlock)(UIImage * image);
#else
typedef void (^TIXboxLiveMessageImageBlock)(NSImage * image);
#endif

@interface TIXboxLiveMessage : TIXboxLiveEngineCookieBase <NSCoding>
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

- (instancetype)initWithMessageID:(NSString *)anID sender:(NSString *)aSender summary:(NSString *)aSummary date:(NSDate *)aDate 
			 readStatus:(TIXboxLiveMessageReadStatus)aStatus attachmentType:(TIXboxLiveMessageAttachmentType)type;

- (BOOL)isEqualToMessage:(TIXboxLiveMessage *)message;
- (BOOL)hasMessageID:(NSString *)anID;
- (BOOL)deleteMessage;
- (BOOL)handleFriendRequest:(BOOL)shouldAccept;

- (void)getMessageWithBodyCallback:(TIXboxLiveMessageBodyBlock)bodyCallback imageCallback:(TIXboxLiveMessageImageBlock)imageCallback;

@end
