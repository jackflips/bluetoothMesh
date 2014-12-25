//
//  PeripheralManager.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/25/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "PeripheralManager.h"

static NSString * const kIdentifier = @"89A66372-BCEE-4BB6-AC92-3A9C78ECA25E";
static NSString * const kWriteCharacteristic = @"4D040DC8-6BDE-417D-AC70-DFF7FE2A6E89";
static NSString * const kIdentityWriteCharacteristic = @"14CCA15E-7C40-4391-BC41-4D6C097C856A";
static NSString * const kReadCharacteristic = @"C8B794F6-357A-4D0E-ADEF-60E16DFA971E";
static NSString * const kIdentityReadCharacteristic = @"EDB06B2B-EFEC-45B2-90C3-72E830CEBD72";

@implementation PeripheralManager

- (id)init {
    self = [super init];
    _peripheralQueue = dispatch_queue_create("peripheralQueue", NULL);
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_peripheralQueue];
    _readSendQueue = [NSMutableArray array];
    return self;
}

+ (instancetype)sharedManager {
    static PeripheralManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if ([_peripheralManager state] == CBCentralManagerStatePoweredOn) {
        _writeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kWriteCharacteristic] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
        _identityWriteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kIdentityWriteCharacteristic] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
        _readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kReadCharacteristic] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
        _identityReadCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kIdentityReadCharacteristic] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
        CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:kIdentifier] primary:YES];
        service.characteristics = @[_writeCharacteristic, _readCharacteristic, _identityWriteCharacteristic, _identityReadCharacteristic];
        [_peripheralManager addService:service];
        [_peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey :
                                                    @[[CBUUID UUIDWithString:kIdentifier]] }];
        
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"peripheral manager did start advertising!");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    NSLog(@"did add service");
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"DEBUG: Peer did subscribe to characteristic");
    Peer *peer = [[Connections sharedManager] getPeerForDevice:central];
    [[Connections sharedManager] doubleConnectionGuard:peer type:PeripheralGuard success:^{
        NSString *currentValue = @"Sixty seconds. That's how long we're required to stand on our metal circles before the sound of a gong releases us. Step off before the minute is up, and land mines blow your legs off.";
        NSLog(@"data to send: %@", [self stringToData:currentValue]);
        [_readSendQueue addObject:[[ReadData alloc] initWithCentral:central andData:[[self stringToData:currentValue] mutableCopy]]];
        if (_readReadyToUpdate) {
            NSLog(@"DEBUG: Ready to update at first, send.");
            [self sendNextReadChunk];
        }
    } failure:^{
        NSLog(@"Double connection, should not be peripheral, not sending anything.");
        peer.central = nil;
    }];
}

- (void)sendNextReadChunk {
    NSLog(@"DEBUG: Sending next read chunk.");
    ReadData *readData = [_readSendQueue firstObject];
    if (readData) {
        _readReadyToUpdate = NO;
        if (readData.data.length > 0) {
            NSUInteger lengthToIncremenent = readData.central.maximumUpdateValueLength < readData.data.length ? readData.central.maximumUpdateValueLength : readData.data.length;
            NSData *chunk = [readData.data subdataWithRange:NSMakeRange(0, lengthToIncremenent)];
            if ([_peripheralManager updateValue:chunk forCharacteristic:_readCharacteristic onSubscribedCentrals:@[readData.central]]) {
                [self sendNextReadChunk];
                NSInteger length = readData.data.length - lengthToIncremenent;
                if (length < 0) length = 0;
                readData.data = [[readData.data subdataWithRange:NSMakeRange(lengthToIncremenent, length)] mutableCopy];
            }
        } else {
            [_peripheralManager updateValue:[NSData data] forCharacteristic:_readCharacteristic onSubscribedCentrals:@[readData.central]];
            [_readSendQueue removeObjectAtIndex:0];
            NSLog(@"done sending data!");
        }
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    _readReadyToUpdate = YES;
    [self sendNextReadChunk];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    [requests enumerateObjectsUsingBlock:^(CBATTRequest* request, NSUInteger idx, BOOL *stop) {
        //NSLog(@"received write request, %@, val: %@", peripheral, [(CBATTRequest*)[requests objectAtIndex:0] value]);
        
        Peer *peer = [[Connections sharedManager] getPeerForDevice:request.central];
        if ([request.characteristic.UUID.UUIDString isEqualToString:kIdentityWriteCharacteristic]) {
            NSLog(@"received identity from write: %@", [self dataToString:request.value]);
            peer.peerID = [self dataToString:request.value];
        } else if ([request.characteristic.UUID.UUIDString isEqualToString:kWriteCharacteristic]) {
            if (!peer.writeInProgress) {
                peer.writeInProgress = [[NSMutableData alloc] init];
            }
            if (request.offset > request.characteristic.value.length) {
                [_peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            } else if (request.offset == 0) {
                if (request.value.length > 0) {
                    [peer.writeInProgress appendData:request.value];
                    [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
                } else {
                    NSLog(@"Received full write: %@", peer.writeInProgress);
                    [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
                }
            }
         }
    }];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    
    Peer *peer = [[Connections sharedManager] getPeerForDevice:request.central];
    [[Connections sharedManager] doubleConnectionGuard:peer type:PeripheralGuard success:^{
        if ([request.characteristic.UUID.UUIDString isEqualToString:kIdentityReadCharacteristic]) {
            if (request.offset > request.characteristic.value.length) {
                [_peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            } else if (request.offset == 0) {
                request.value = [self stringToData:[[Connections sharedManager] identity]];
                [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
            } else {
                NSAssert(true, @"request offset exceded in identity handler");
            }
        }
    } failure:^{
        NSLog(@"Received identity read request but won't send");
    }];
}

- (NSData*)stringToData:(NSString*)str {
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)dataToString:(NSData*)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


@end