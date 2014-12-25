//
//  ConnectionManager.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/25/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CentralManager.h"

@interface ConnectionManager : NSObject

@property (strong, nonatomic) CentralManager *centralManager;

@end
