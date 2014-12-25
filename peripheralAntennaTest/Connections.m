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
    _identity = [self randomString:10];
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

- (Peer*)getPeerForDevice:(id)device {
    CBUUID *identifier = (CBUUID*)[device identifier];
    NSString *idOfDevice = identifier.UUIDString;
    for (Peer *peer in _connections) {
        if ([[peer deviceID] isEqualToString:idOfDevice]) {
            return peer;
        }
    }
    
    //if no match found, create a new peer
    Peer *newPeer = [[Peer alloc] initWithDevice:device];
    [_connections addObject:newPeer];
    return newPeer;
}

- (void)doubleConnectionGuard:(Peer*)peer type:(ConnectionGuardType)type success:(void (^)())success failure:(void (^)())failure {
    if (!peer.peripheral && !peer.central) {
        success();
    } else if (peer.peripheral && type == CentralGuard) {
        success();
    } else if (!peer.peerID) {
        success();
    } else if (peer.peripheral && peer.central) {
        if ([peer.peerID caseInsensitiveCompare:_identity] == NSOrderedAscending) {
            if (type == CentralGuard) {
                success();
            } else if (type == PeripheralGuard) {
                failure();
            }
        } else {
            if (type == CentralGuard) {
                failure();
            } else if (type == PeripheralGuard) {
                success();
            }
        }
    }
}

- (NSString*)randomString:(int)length {
    NSMutableString *str = [[NSMutableString alloc] init];
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int i=0; i<length; i++) {
        [str appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((u_int32_t)[letters length]) % [letters length]]];
    }
    return str;
}

@end
