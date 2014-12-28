//
//  WriteData.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/22/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;

@interface WriteData : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSString *characteristicID;

- (id)initWithPeripheral:(CBPeripheral*)peripheral data:(NSData*)data andCharacteristic:characteristic;

@end
