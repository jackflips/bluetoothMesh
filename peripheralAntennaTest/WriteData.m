//
//  WriteData.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/22/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "WriteData.h"

@implementation WriteData

- (id)initWithPeripheral:(CBPeripheral*)peripheral data:(NSData*)data andCharacteristic:characteristic {
    self = [super init];
    _peripheral = peripheral;
    _data = [data mutableCopy];
    _characteristicID = characteristic;
    return self;
}

@end
