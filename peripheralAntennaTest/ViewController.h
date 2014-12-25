//
//  ViewController.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/17/14.
//  Copyright (c) 2014 ;. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReadData.h"
#import "WriteData.h"
#import "ConnectedDevice.h"
@import CoreBluetooth;

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate>

@property (strong, nonatomic) NSString *myIdentity;
@property (strong, nonatomic) NSMutableArray *foundDevices;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) dispatch_queue_t centralQueue;
@property (strong, nonatomic) dispatch_queue_t peripheralQueue;
@property (strong, nonatomic) CBMutableCharacteristic *writeCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *identityWriteCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *readCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *identityReadCharacteristic;

@property (strong, nonatomic) NSMutableData *dataSoFarRead;
@property (strong, nonatomic) NSMutableData *dataSoFarWrite;
@property (strong, nonatomic) NSMutableArray *readSendQueue;
@property (strong, nonatomic) NSMutableArray *writeSendQueue;
@property (nonatomic) BOOL readReadyToUpdate;
@property (nonatomic) BOOL writeReadyToUpdate;

@end

