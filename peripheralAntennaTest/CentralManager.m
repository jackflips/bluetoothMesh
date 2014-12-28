//
//  CentralManager.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/24/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "CentralManager.h"

static NSString * const kIdentifier = @"89A66372-BCEE-4BB6-AC92-3A9C78ECA25E";
static NSString * const kWriteCharacteristic = @"4D040DC8-6BDE-417D-AC70-DFF7FE2A6E89";
static NSString * const kIdentityWriteCharacteristic = @"14CCA15E-7C40-4391-BC41-4D6C097C856A";
static NSString * const kReadCharacteristic = @"C8B794F6-357A-4D0E-ADEF-60E16DFA971E";
static NSString * const kIdentityReadCharacteristic = @"EDB06B2B-EFEC-45B2-90C3-72E830CEBD72";

@implementation CentralManager

- (id)init {
    self = [super init];
    _centralQueue = dispatch_queue_create("centralQueue", NULL);
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_centralQueue];
    _writeSendQueue = [NSMutableArray array];
    _writeReadyToUpdate = YES;
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
    Peer *peer = [[Connections sharedManager] getPeerForDevice:peripheral];
    [[Connections sharedManager] doubleConnectionGuard:peer type:CentralGuard success:^() {
        [_centralManager connectPeripheral:peer.peripheral options:nil];
    } failure:^() {
        NSLog(@"In CentralDidDiscoverPeripheral ConnectionGuard prevented connection.");
    }];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Central failed to connect with error: %@",  error);
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
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kReadCharacteristic], [CBUUID UUIDWithString:kIdentityReadCharacteristic], [CBUUID UUIDWithString:kWriteCharacteristic], [CBUUID UUIDWithString:kIdentityWriteCharacteristic]] forService:service];
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    Peer *peer = [[Connections sharedManager] getPeerForDevice:peripheral];
    [self readIdentity:peer]; //don't double connection guard yet because we don't yet have an identity for the other device
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    Peer *peer = [[Connections sharedManager] getPeerForDevice:peripheral];
    peer.peripheral = peripheral;
    if ([characteristic.UUID.UUIDString isEqualToString:kIdentityReadCharacteristic]) {
        if ([self dataToString:characteristic.value].length < 1) { //sometimes it reads an empty identity. Not sure why.
            return;
        }
        peer.peerID = [self dataToString:characteristic.value];
        NSLog(@"read identity, %@", peer.peerID);
        
        [[Connections sharedManager] doubleConnectionGuard:peer type:CentralGuard success:^() {
            [self subscribeToReadCharacteristic:peer];
            [self writeIdentity:peer];
            //Ready to send arbirary messages now.
        } failure:^() {
            NSLog(@"In didUpdate for Identity Char, shouldn't be central, disconnecting.");
            [_centralManager cancelPeripheralConnection:peripheral];
            return;
        }];  
    } else { //data characteristic
        if (characteristic.value.length > 0) {
            if (!peer.readInProgress) {
                peer.readInProgress = [[NSMutableData alloc] init];
            }
            [peer.readInProgress appendData:characteristic.value];
        } else { //finished reading data
            NSLog(@"Finished reading data, %@", [self dataToString:peer.readInProgress]);
            [_delegate receivedMessage:[self dataToString:peer.readInProgress] peer:peer.peerID];
            peer.readInProgress = nil;
        }
    }
}

- (void)writeMessage:(NSData*)message toPeer:(Peer*)peer onCharacteristic:(NSString*)characteristic {
    [_writeSendQueue addObject:[[WriteData alloc] initWithPeripheral:peer.peripheral data:message andCharacteristic:characteristic]];
    if (_writeReadyToUpdate) {
        [self sendNextWriteChunk];
    }
}

- (void)writeIdentity:(Peer*)peer {
    [self writeMessage:[self stringToData:[[Connections sharedManager] identity]] toPeer:peer onCharacteristic:kIdentityWriteCharacteristic];
    [_writeSendQueue removeObjectAtIndex:0];
}

- (void)sendNextWriteChunk {
    WriteData *writeData = [_writeSendQueue firstObject];
    if (writeData) {
        if (writeData.data.length > 0) {
            _writeReadyToUpdate = NO;
            NSUInteger lengthToIncremenent = 512 < writeData.data.length ? 512 : writeData.data.length;
            NSData *chunk = [writeData.data subdataWithRange:NSMakeRange(0, lengthToIncremenent)];
            NSInteger length = writeData.data.length - lengthToIncremenent;
            if (length < 0) length = 0;
            writeData.data = [[writeData.data subdataWithRange:NSMakeRange(lengthToIncremenent, length)] mutableCopy];
            if ([writeData.characteristicID isEqualToString:kIdentityWriteCharacteristic]) {
                [writeData.peripheral writeValue:chunk forCharacteristic:[self getIdentityWriteCharacteristicOfPeripheral:writeData.peripheral] type:CBCharacteristicWriteWithResponse];
            } else if ([writeData.characteristicID isEqualToString:kWriteCharacteristic]) {
                [writeData.peripheral writeValue:chunk forCharacteristic:[self getWriteCharacteristicOfPeripheral:writeData.peripheral] type:CBCharacteristicWriteWithResponse];
            }
            
        } else if (writeData.characteristicID == kWriteCharacteristic) { //only end with empty data if its a data write
            [writeData.peripheral writeValue:[NSData data] forCharacteristic:[self getWriteCharacteristicOfPeripheral:writeData.peripheral] type:CBCharacteristicWriteWithResponse];
            [_writeSendQueue removeObjectAtIndex:0];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    _writeReadyToUpdate = YES;
    [self sendNextWriteChunk];
}

- (void)readIdentity:(Peer*)peer {
    for (CBService *service in peer.peripheral.services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:kIdentityReadCharacteristic]) {
                [peer.peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
}

- (CBCharacteristic*)getCharacteristicOfType:(NSString*)type fromPeripheral:(CBPeripheral*)peripheral {
    NSArray *services = peripheral.services;
    for (CBService *service in services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:type]) {
                return characteristic;
            }
        }
    }
    NSLog(@"Warning: Didn't find characteristic on peripheral %@ for type %@", peripheral, type);
    return nil;
}

- (CBCharacteristic*)getWriteCharacteristicOfPeripheral:(CBPeripheral*)peripheral {
    return [self getCharacteristicOfType:kWriteCharacteristic fromPeripheral:peripheral];
}

- (CBCharacteristic*)getIdentityWriteCharacteristicOfPeripheral:(CBPeripheral*)peripheral {
    return [self getCharacteristicOfType:kIdentityWriteCharacteristic fromPeripheral:peripheral];
}

- (void)subscribeToReadCharacteristic:(Peer*)peer {
    for (CBService *service in peer.peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:kIdentifier]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID.UUIDString isEqualToString:kReadCharacteristic]) {
                    [peer.peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (NSData*)stringToData:(NSString*)str {
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)dataToString:(NSData*)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)sendMessage:(NSString*)message toPeer:(Peer *)peer {
    [self writeMessage:[self stringToData:message] toPeer:peer onCharacteristic:kWriteCharacteristic];
}



@end
