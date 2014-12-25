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

@interface CentralManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) dispatch_queue_t centralQueue;

@end
