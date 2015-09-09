//
//  ManualDescription.h
//  debugDescription-Demo
//
//  Created by Samantha Marshall on 5/9/15.
//  Copyright (c) 2015 Samantha Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Position.h"

@interface ManualDescription : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, readwrite) float distance;
@property (nonatomic, readwrite) NSInteger itemCount;
@property (nonatomic, strong) NSString *level;
@property (nonatomic, readwrite) struct Position pos;
@property (nonatomic, strong) NSDictionary *dict;

@property (nonatomic, readwrite) void * ptr;
@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, readwrite) BOOL isAvailable;

@end
