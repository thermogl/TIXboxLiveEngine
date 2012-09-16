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
@synthesize name;
@synthesize value;

- (id)initWithName:(NSString *)aName value:(NSString *)aValue {
	
	if ((self = [super init])){
		name = [aName copy];
		value = [aValue copy];
	}
	
    return self;
}

- (NSString *)safeURLRepresentation {
    return [NSString stringWithFormat:@"%@=%@", name.encodedURLParameterString, value.encodedURLParameterString];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<URLRequestParameter %p; name = \"%@\"; value = \"%@\">", self, name, value];
}

- (void)dealloc {
	[name release];
	[value release];
	[super dealloc];
}

@end
