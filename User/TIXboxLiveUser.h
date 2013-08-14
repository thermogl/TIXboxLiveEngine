//
//  TIXboxLiveUser.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 03/01/2011.
//  Copyright 2011 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieBase.h"

extern NSString * const TIXboxLiveUserDidReceiveGamerProfileNotificationName;
extern NSString * const TIXboxLiveUserDidFinishChangingGamerProfileNotificationName;

typedef void (^TIXboxLiveUserProfileBlock)(NSError * error);

@class TIXboxLiveFriend;
@interface TIXboxLiveUser : TIXboxLiveEngineCookieBase <NSCoding>
@property (nonatomic, copy) NSString * gamertag;
@property (nonatomic, copy) NSString * gamerscore;
@property (nonatomic, copy) NSString * realName;
@property (nonatomic, copy) NSString * motto;
@property (nonatomic, copy) NSString * location;
@property (nonatomic, copy) NSString * bio;
@property (nonatomic, copy) NSURL * tileURL;

- (instancetype)initWithGamertag:(NSString *)aTag gamerscore:(NSString *)aScore tileURL:(NSURL *)aURL;

- (void)getGamerProfileWithCallback:(TIXboxLiveUserProfileBlock)callback;
- (void)changeGamerProfileName:(NSString *)name motto:(NSString *)newMotto location:(NSString *)newLocation bio:(NSString *)newBio callback:(TIXboxLiveUserProfileBlock)callback;

- (BOOL)isEqualToUser:(TIXboxLiveUser *)user;
- (BOOL)isEqualToFriend:(TIXboxLiveFriend *)friend;

@end