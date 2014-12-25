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

- (id)initWithPeripheral:(CBPeripheral*)peripheral andData:(NSData*)data;

@end
