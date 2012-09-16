//
//  TIURLRequestParameter.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 22/09/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

@interface TIURLRequestParameter : NSObject {
	
    NSString * name;
    NSString * value;
}

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * value;

- (id)initWithName:(NSString *)aName value:(NSString *)aValue;
- (NSString *)safeURLRepresentation;

@end