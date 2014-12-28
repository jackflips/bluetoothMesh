//
//  ViewController.h
//  peripheralAntennaTest
//
//  Created by John Rogers on 12/17/14.
//  Copyright (c) 2014 ;. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ConnectionManager.h"

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ConnectionManagerDelegate>

@property (strong, nonatomic) NSMutableArray *tableSource;
@property (strong, nonatomic) IBOutlet UITextField *messageForm;
@property (strong, nonatomic) IBOutlet UITableView *messagesTableView;
@property (strong, nonatomic) ConnectionManager *connectionManager;

@end

