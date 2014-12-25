//
//  Connections.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/25/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConnectedDevice.h"

@interface Connections : NSObject

@property (strong, nonatomic) NSMutableArray *connections;

+ (instancetype)sharedManager;

- (ConnectedDevice*)getPeerForDevice;

@end
