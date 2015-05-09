//
//  ManualDescription.m
//  debugDescription-Demo
//
//  Created by Sam Marshall on 5/9/15.
//  Copyright (c) 2015 Sam Marshall. All rights reserved.
//

#import "ManualDescription.h"

@implementation ManualDescription

- (NSString *)debugDescription
{
	NSMutableString *formattedDescription = [NSMutableString new];

	[formattedDescription appendFormat:@"<%@: %p>", [self className], self];
	[formattedDescription appendFormat:@"\n"];
	[formattedDescription appendFormat:@"name: %@", _name];
	[formattedDescription appendFormat:@"\n"];
	[formattedDescription appendFormat:@"distance: %f", _distance];
	[formattedDescription appendFormat:@"\n"];
	[formattedDescription appendFormat:@"itemCount: %ld", _itemCount];
	[formattedDescription appendFormat:@"\n"];
	[formattedDescription appendFormat:@"level: %@", _level];
	[formattedDescription appendFormat:@"\n"];
	[formattedDescription appendFormat:@"pos = {\n\
	 \t.x = %f\n\
	 \t.y = %f\n\
	 \t.z = %f\n\
	 }",
						  _pos.x,
						  _pos.y,
						  _pos.z];
	[formattedDescription appendFormat:@"\n"];
	[formattedDescription appendFormat:@"dict: %@", _dict];
	[formattedDescription appendFormat:@"\n"];

	return [formattedDescription copy];
}

@end
