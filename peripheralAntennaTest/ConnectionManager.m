//
//  ConnectionManager.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/26/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "ConnectionManager.h"

@implementation ConnectionManager

- (id)init {
    self = [super init];
    _peripheralManager = [PeripheralManager sharedManager];
    _peripheralManager.delegate = self;
    _centralManager = [CentralManager sharedManager];
    _centralManager.delegate = self;
    return self;
}

- (void)receivedMessage:(NSString*)message peer:(NSString *)peerID {
    [_delegate receivedMessage:message peer:peerID];
}

- (void)sendMessage:(NSString*)message {
    
    for (Peer *peer in [Connections sharedManager].connections) {
        [[Connections sharedManager] is:peer central:^{
            [_centralManager sendMessage:message toPeer:peer];
        } orPeripheral:^{
            [_peripheralManager sendMessage:message toPeer:peer];
        }];
    }
}

@end
