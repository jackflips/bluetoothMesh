//
//  PeripheralManager.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/25/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReadData.h"
#import "Peer.h"
#import "Connections.h"

@interface PeripheralManager : NSObject <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) dispatch_queue_t peripheralQueue;
@property (strong, nonatomic) CBMutableCharacteristic *writeCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *identityWriteCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *readCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *identityReadCharacteristic;

@property (strong, nonatomic) NSMutableArray *readSendQueue;
@property (nonatomic) BOOL readReadyToUpdate;

+ (instancetype)sharedManager;

@end
