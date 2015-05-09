//
//  main.m
//  debugDescription-Demo
//
//  Created by Sam Marshall on 5/9/15.
//  Copyright (c) 2015 Sam Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ManualDescription.h"
#import "AutoDescription.h"

void SetDefaults(id obj)
{
	[obj setName:@"Sam"];

	[obj setDistance:123.456f];

	[obj setItemCount:8];

	[obj setLevel:@"5"];

	struct Position pos = {
		.x = 1295.f,
		.y = 95.1f,
		.z = 0.13};
	[obj setPos:pos];

	NSDictionary *dict = @{
		@"a" : @1,
		@"b" : @2,
		@"c" : @3,
		@"d" : @4,
		@"e" : @5
	};
	[obj setDict:dict];

	//	[obj setPtr:(void*)0x41414141];
	//	[obj setObjects:@[@"hello", @", ", @"world", @"!"]];
	//	[obj setIsAvailable:NO];
}

int main(int argc, const char *argv[])
{
	@autoreleasepool
	{
		AutoDescription *auto_description = [[AutoDescription alloc] init];
		SetDefaults(auto_description);
		NSLog(@"%@", [auto_description debugDescription]);
		NSLog(@"================================\n\n");
		ManualDescription *manual_description = [[ManualDescription alloc] init];
		SetDefaults(manual_description);
		NSLog(@"%@", [manual_description debugDescription]);
	}
	return 0;
}
