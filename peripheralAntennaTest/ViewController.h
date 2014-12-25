//
//  ViewController.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/17/14.
//  Copyright (c) 2014 ;. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "CentralManager.h"
#import "PeripheralManager.h"

@interface ViewController : UIViewController

@property (strong, nonatomic) CentralManager *central;
@property (strong, nonatomic) PeripheralManager *peripheral;

@end

