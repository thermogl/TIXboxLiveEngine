//
//  TIURLRequestParameter.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 22/09/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIURLRequestParameter.h"
#import "TIXboxLiveEngineAdditions.h"

@implementation TIURLRequestParameter
@synthesize name = _name;
@synthesize value = _value;

- (instancetype)initWithName:(NSString *)aName value:(NSString *)aValue {
	
	if ((self = [super init])){
		_name = [aName copy];
		_value = [aValue copy];
	}
	
    return self;
}

- (NSString *)safeURLRepresentation {
    return [NSString stringWithFormat:@"%@=%@", _name.encodedURLParameterString, _value.encodedURLParameterString];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<URLRequestParameter %p; name = \"%@\"; value = \"%@\">", self, _name, _value];
}

@end
