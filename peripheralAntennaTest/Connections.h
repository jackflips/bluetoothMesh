//
//  Connections.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/25/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Peer.h"

typedef NS_ENUM(NSInteger, ConnectionGuardType) {
    CentralGuard,
    PeripheralGuard
};

@interface Connections : NSObject

@property (strong, nonatomic) NSMutableArray *connections;
@property (strong, nonatomic) NSString *identity;

+ (instancetype)sharedManager;

- (Peer*)getPeerForDevice:(id)device;
- (void)doubleConnectionGuard:(Peer*)peer type:(ConnectionGuardType)type success:(void (^)())success failure:(void (^)())failure;
- (void)is:(Peer*)peer central:(void(^)())central orPeripheral:(void (^)())peripheral;

@end
