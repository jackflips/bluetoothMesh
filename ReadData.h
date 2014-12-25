//
//  ReadData.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/22/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;

@interface ReadData : NSObject

@property (strong, nonatomic) CBCentral *central;
@property (strong, nonatomic) NSMutableData *data;

- (id)initWithCentral:(CBCentral*)central andData:(NSMutableData*)data;

@end
