//
//  CentralManager.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/24/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReadData.h"
#import "WriteData.h"
#import "Connections.h"

@protocol CentralManagerDelegate <NSObject>

- (void)receivedMessage:(NSString*)message peer:(NSString*)peerID;

@end

@interface CentralManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) dispatch_queue_t centralQueue;
@property (strong, nonatomic) NSMutableArray *writeSendQueue;
@property (nonatomic) BOOL writeReadyToUpdate;
@property (strong, nonatomic) id delegate;

+ (instancetype)sharedManager;
- (void)sendMessage:(NSString*)message toPeer:(Peer*)peer;

@end
