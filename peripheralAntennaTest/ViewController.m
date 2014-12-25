//
//  ViewController.m
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/17/14.
//  Copyright (c) 2014 jackrogers. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _central = [CentralManager sharedManager];
    _peripheral = [PeripheralManager sharedManager];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
