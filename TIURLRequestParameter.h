//
//  TIURLRequestParameter.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 22/09/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

@interface TIURLRequestParameter : NSObject
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * value;
@property (nonatomic, readonly) NSString * safeURLRepresentation;

- (instancetype)initWithName:(NSString *)aName value:(NSString *)aValue;

@end