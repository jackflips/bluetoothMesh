//
//  ConnectedDevice.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/23/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "ConnectedDevice.h"

@implementation ConnectedDevice

- (id)initWithDevice:(id)device {
    self = [super init];
    if ([device isKindOfClass:[CBPeripheral class]]) {
        _peripheral = device;
    } else if ([device isKindOfClass:[CBCentral class]]) {
        _central = device;
    }
    return self;
}

- (NSString*)deviceID {
    if (_peripheral) {
        CBUUID *identifier = (CBUUID*)[_peripheral identifier];
        return identifier.UUIDString;
    } else if (_central) {
        CBUUID *identifier = (CBUUID*)[_peripheral identifier];
        return identifier.UUIDString;
    } else {
        NSAssert(true, @"Request for device ID when there are no devices.");
        return nil;
    }
}

@end
