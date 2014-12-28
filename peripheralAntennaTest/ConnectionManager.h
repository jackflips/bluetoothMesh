//
//  ConnectionManager.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/26/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeripheralManager.h"
#import "CentralManager.h"

@protocol ConnectionManagerDelegate <NSObject>

- (void)receivedMessage:(NSString*)message peer:(NSString *)peerID;

@end

@interface ConnectionManager : NSObject <PeripheralManagerDelegate, CentralManagerDelegate>

@property (strong, nonatomic) PeripheralManager *peripheralManager;
@property (strong, nonatomic) CentralManager *centralManager;
@property (strong, nonatomic) id delegate;

- (void)sendMessage:(NSString*)message;

@end
