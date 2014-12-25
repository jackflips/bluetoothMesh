//
//  ConnectedDevice.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/23/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;

@interface ConnectedDevice : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCentral *central;
@property (strong, nonatomic) NSString *peerID;
@property (strong, nonatomic) NSMutableData *writeInProgress;

- (id)initWithDevice:(id)device;
- (NSString*)deviceID;

@end
