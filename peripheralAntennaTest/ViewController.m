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
    _connectionManager = [[ConnectionManager alloc] init];
    _connectionManager.delegate = self;
    _tableSource = [NSMutableArray array];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sendButtonPressed:(id)sender {
    [_connectionManager sendMessage:_messageForm.text];
    _messageForm.text = @"";
    NSLog(@"sending message to peers:");
    for (Peer *peer in [[Connections sharedManager] connections]) {
        NSLog(@"Peer: %@", peer.peerID);
    }
}

- (void)receivedMessage:(NSString *)message peer:peerID {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableSource addObject:[NSString stringWithFormat:@"%@: %@", peerID, message]];
        [_messagesTableView reloadData];
        NSLog(@"finished adding to tableview");
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tableSource count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Set the data for this cell:
    
    cell.textLabel.text = [_tableSource objectAtIndex:indexPath.row];
    return cell;
}

@end
