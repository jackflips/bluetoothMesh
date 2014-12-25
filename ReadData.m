//
//  ReadData.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/22/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "ReadData.h"


@implementation ReadData

- (id)initWithCentral:(CBCentral*)central andData:(NSMutableData*)data {
    self = [super init];
    _central = central;
    _data = data;
    return self;
}

@end
