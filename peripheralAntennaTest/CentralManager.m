//
//  CentralManager.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/24/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "CentralManager.h"

static NSString * const kIdentifier = @"89A66372-BCEE-4BB6-AC92-3A9C78ECA25E";

@implementation CentralManager

- (id)init {
    self = [super init];
    _centralQueue = dispatch_queue_create("centralQueue", NULL);
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_centralQueue];
    return self;
}

+ (instancetype)sharedManager {
    static CentralManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if ([central state] == CBCentralManagerStatePoweredOn) {
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kIdentifier]] options:nil];
    }
}

- (void)doubleConnectionGuard {
    NSLog(@"guard");
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    ConnectedDevice *device = 
    [self doubleConnectionGuard:device];
    
    NSLog(@"did discover peripheral");
    NSLog(@"in connect method: %@", [self deviceForID:peripheral.identifier.UUIDString]);
    if (![[self deviceForID:peripheral.identifier.UUIDString] central]) {
        NSLog(@"should connect to %@", peripheral);
        [central connectPeripheral:peripheral options:nil];
        [_foundDevices addObject:[[ConnectedDevice alloc] initWithDevice:peripheral]];
    } else {
        NSLog(@"device already seen, not connecting.");
    }
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"failed with error: %@",  error);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"did connect");
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kIdentifier]]];
    peripheral.delegate = self;
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"central did discover");
    NSArray *services = peripheral.services;
    [services enumerateObjectsUsingBlock:^(CBService *service, NSUInteger idx, BOOL *stop) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kWriteCharacteristic], [CBUUID UUIDWithString:kReadCharacteristic], [CBUUID UUIDWithString:kIdentityReadCharacteristic], [CBUUID UUIDWithString:kIdentityWriteCharacteristic]] forService:service];
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    [self readIdentity:peripheral];
    //[self subscribeToReadCharacteristic:peripheral];
}


@end
