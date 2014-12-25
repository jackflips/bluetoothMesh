//
//  Connections.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/25/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "Connections.h"

@implementation Connections

- (id)init {
    self = [super init];
    _connections = [NSMutableArray array];
    return self;
}

+ (instancetype)sharedManager {
    static Connections *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

@end
