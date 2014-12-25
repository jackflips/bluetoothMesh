//
//  ViewController.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/17/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "ViewController.h"

static NSString * const kIdentifier = @"89A66372-BCEE-4BB6-AC92-3A9C78ECA25E";
static NSString * const kWriteCharacteristic = @"4D040DC8-6BDE-417D-AC70-DFF7FE2A6E89";
static NSString * const kIdentityWriteCharacteristic = @"14CCA15E-7C40-4391-BC41-4D6C097C856A";
static NSString * const kReadCharacteristic = @"C8B794F6-357A-4D0E-ADEF-60E16DFA971E";
static NSString * const kIdentityReadCharacteristic = @"EDB06B2B-EFEC-45B2-90C3-72E830CEBD72";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _centralQueue = dispatch_queue_create("centralQueue", NULL);
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_centralQueue];
    _peripheralQueue = dispatch_queue_create("peripheralQueue", NULL);
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_peripheralQueue];
    _myIdentity = [self randomString:10];
    _dataSoFarRead = [[NSMutableData alloc] init];
    _dataSoFarWrite = [[NSMutableData alloc] init];
    _readSendQueue = [NSMutableArray array];
    _writeSendQueue = [NSMutableArray array];
    _foundDevices = [NSMutableArray array];
    _readReadyToUpdate = YES;
    _writeReadyToUpdate = YES;
    // Do any additional setup after loading the view, typically from a nib.
}



#pragma mark central methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([central state] == CBCentralManagerStatePoweredOn) {
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kIdentifier]] options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
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

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    ConnectedDevice *device = [self deviceForID:peripheral.identifier.UUIDString];
    //NSLog(@"recieved msg: %@, %@, and peripheral: %@ with error %@", characteristic.UUID.UUIDString, characteristic.value, peripheral.identifier.UUIDString, error);
    
    if ([characteristic.UUID.UUIDString isEqualToString:kIdentityReadCharacteristic]) {
        device.peerID = [self dataToString:characteristic.value];
        NSLog(@"read identity, %@", device.peerID);
        if ([self checkDoubleConnection:device]) {
            NSLog(@"double connection");
            if (![self shouldBeCentral:device]) {
                [_centralManager cancelPeripheralConnection:peripheral];
                return;
            }
        }
        [self subscribeToReadCharacteristic:peripheral];
    } else {
        if (characteristic.value.length > 0) {
            [_dataSoFarRead appendData:characteristic.value];
        } else {
            NSLog(@"Finished reading data");
            [self writeIdentity:device];
            NSString *message = @"'Things could change, Gabe', Jonas went on. Things could be different. I don't know how, but there must be some way for things to be different. There could be colors. And grandparents,[ he added, staring through the dimness toward the ceiling of his sleepingroom. 'And everybody would have the memories.' You know the memories,' he whispered, turning toward the crib. Garbriel's breathing was even and deep. Jonas liked having him there, though he felt guilty about the secret. Each night he gave memories to Gabriel: memories of boat rides and picnics in the sun; memories of soft rainfall against windowpanes; memories of dancing barefoot on a damp lawn. 'Gabe?' The newchild stirred slightly in his sleep. Jonas looked over at him. 'There could be love,' Jonas whispered.'";
            NSLog(@"Writing data now.");
            NSData *messageData = [self stringToData:message];
            [_writeSendQueue addObject:[[WriteData alloc] initWithPeripheral:peripheral andData:messageData]];
            if (_writeReadyToUpdate) {
                [self sendNextWriteChunk];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"Write chunk to other peer finished, error? %@", error);
    _writeReadyToUpdate = YES;
    [self sendNextWriteChunk];
}

- (void)subscribeToReadCharacteristic:(CBPeripheral*)peripheral {
    for (CBService *service in peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:kIdentifier]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID.UUIDString isEqualToString:kReadCharacteristic]) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)readIdentity:(CBPeripheral*)peripheral {
    for (CBService *service in peripheral.services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:kIdentityReadCharacteristic]) {
                [peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
}

#pragma mark peripheralManager methods

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

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    ConnectedDevice *device = [self deviceForID:central.identifier.UUIDString];
    device.central = central;
    NSLog(@"in didSubscribe, device.central: %@, device.peripheral: %@", device.central, device.peripheral);
    if ([self checkDoubleConnection:device]) {
        NSLog(@"double connection found");
        if ([self shouldBeCentral:device]) {
            NSLog(@"should be central");
            device.central = nil;
            NSLog(@"Should not be peripheral, not sending anything and returning.");
            return;
        } else {
            device.central = central;
        }
    } else {
        [_foundDevices addObject:[[ConnectedDevice alloc] initWithDevice:central]];
    }
    NSString *currentValue = @"Sixty seconds. That's how long we're required to stand on our metal circles before the sound of a gong releases us. Step off before the minute is up, and land mines blow your legs off. Sixty seconds to take in the ring of tributes all equidistant from the Cornucopia, a giant golden horn shaped like a cone with a curved tail, the mouth of which is at least twenty feet high, spilling over with the things that will give us life here in the arena. Food, containers of water, weapons, medicine, garments, fire starters. Strewn around the Cornucopia are other supplies, their value decreasing the farther they are from the horn. For instance, only a few steps from my feet lies a three-foot square of plastic. Certainly it could be of some use in a downpour. But there in the mouth, I can see a tent pack that would protect from almost any sort of weather. If I had the guts to go in and fight for it against the other twenty-three tributes. Which I have been instructed not to do.";
    
    NSLog(@"data to send: %@", [self stringToData:currentValue]);
    
    [_readSendQueue addObject:[[ReadData alloc] initWithCentral:central andData:[[self stringToData:currentValue] mutableCopy]]];
    if (_readReadyToUpdate) {
        [self sendNextReadChunk];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    //[_foundDevices removeObject:[self deviceForID:central.identifier.UUIDString]];
}

- (void)sendNextReadChunk {
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

- (void)sendNextWriteChunk {
    WriteData *writeData = [_writeSendQueue firstObject];
    if (writeData) {
        if (writeData.data.length > 0) {
            _writeReadyToUpdate = NO;
            NSUInteger lengthToIncremenent = 512 < writeData.data.length ? 512 : writeData.data.length;
            NSData *chunk = [writeData.data subdataWithRange:NSMakeRange(0, lengthToIncremenent)];
            NSLog(@"sending write chunk %@", chunk);
            NSInteger length = writeData.data.length - lengthToIncremenent;
            if (length < 0) length = 0;
            writeData.data = [[writeData.data subdataWithRange:NSMakeRange(lengthToIncremenent, length)] mutableCopy];
            [writeData.peripheral writeValue:chunk forCharacteristic:[self getWriteCharacteristicOfPeripheral:writeData.peripheral] type:CBCharacteristicWriteWithResponse];
        } else {
            [writeData.peripheral writeValue:[NSData data] forCharacteristic:[self getWriteCharacteristicOfPeripheral:writeData.peripheral] type:CBCharacteristicWriteWithResponse];
            [_writeSendQueue removeObjectAtIndex:0];
            NSLog(@"finished writing.");
        }
    }
}

- (void)writeIdentity:(ConnectedDevice*)device {
    NSLog(@"will write identity");
    [device.peripheral writeValue:[self stringToData:_myIdentity]
                forCharacteristic:[self getWriteCharacteristicOfPeripheral:device.peripheral] type:CBCharacteristicWriteWithResponse];
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    _readReadyToUpdate = YES;
    [self sendNextReadChunk];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    [requests enumerateObjectsUsingBlock:^(CBATTRequest* request, NSUInteger idx, BOOL *stop) {
        //NSLog(@"received write request, %@, val: %@", peripheral, [(CBATTRequest*)[requests objectAtIndex:0] value]);
        ConnectedDevice *device = [self deviceForID:request.central.identifier.UUIDString];
        if ([request.characteristic.UUID.UUIDString isEqualToString:kIdentityWriteCharacteristic]) {
            NSLog(@"read identity from write: %@", [self dataToString:request.value]);
            device.peerID = [self dataToString:request.value];
        } else if ([request.characteristic.UUID.UUIDString isEqualToString:kWriteCharacteristic]) {
            if (!device.writeInProgress) {
                device.writeInProgress = [[NSMutableData alloc] init];
            }
            if (request.offset > request.characteristic.value.length) {
                [_peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            } else if (request.offset == 0) {
                if (request.value.length > 0) {
                    [device.writeInProgress appendData:request.value];
                    [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
                } else {
                    NSLog(@"Received full write: %@", device.writeInProgress);
                    [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
                }
            } else {
                [device.writeInProgress appendData:request.value];
                [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
            }
        }
    }];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    ConnectedDevice *device = [self deviceForID:request.central.identifier.UUIDString];
    if (device.central && device.peerID) {
        NSAssert(true, @"Already received device id");
    }
    NSLog(@"received read request: %@", peripheral);
    if ([request.characteristic.UUID.UUIDString isEqualToString:kIdentityReadCharacteristic]) {
        if (request.offset > request.characteristic.value.length) {
            [_peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
        } else if (request.offset == 0) {
            request.value = [self stringToData:_myIdentity];
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        } else {
            NSAssert(true, @"request offset exceded in identity handler");
        }
    }
}

#pragma mark utils

- (BOOL)checkDoubleConnection:(ConnectedDevice*)device {
    if (device.central && device.peripheral) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)shouldBeCentral:(ConnectedDevice*)device {
    NSAssert(device.peerID, @"Device doesn't have an ID");
    if ([device.peerID caseInsensitiveCompare:_myIdentity] == NSOrderedAscending) {
        return YES;
    } else {
        return NO;
    }
    
}

- (id)deviceForID:(NSString*)ID {
    for (ConnectedDevice *device in _foundDevices) {
        if ([[device deviceID] isEqualToString:ID]) {
            return device;
        }
    }
    return nil;
}

- (CBCharacteristic*)getReadCharacteristicOfPeripheral:(CBPeripheral*)peripheral {
    return [self getCharacteristicOfType:kReadCharacteristic fromPeripheral:peripheral];
}

- (CBCharacteristic*)getWriteCharacteristicOfPeripheral:(CBPeripheral*)peripheral {
    return [self getCharacteristicOfType:kWriteCharacteristic fromPeripheral:peripheral];
}

- (CBCharacteristic*)getIdentityWriteCharacteristicOfPeripheral:(CBPeripheral*)peripheral {
    return [self getCharacteristicOfType:kIdentityWriteCharacteristic fromPeripheral:peripheral];
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

- (NSData*)stringToData:(NSString*)str {
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)dataToString:(NSData*)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData*)intToData:(int)num {
    return [NSData dataWithBytes:&num length:sizeof(int)];
}

- (int)dataToInt:(NSData*)data {
    int value;
    [data getBytes:&value length:sizeof(int)];
    return value;
}

- (NSString*)randomString:(int)length {
    NSMutableString *str = [[NSMutableString alloc] init];
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int i=0; i<length; i++) {
        [str appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((u_int32_t)[letters length]) % [letters length]]];
    }
    return str;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
