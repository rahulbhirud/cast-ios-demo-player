// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "DeviceListTableViewController.h"
#import "AppDelegate.h"
#import "CastViewController.h"

@interface DeviceListTableViewController () <GCKDeviceManagerListener> {
  NSMutableArray *_devices;
}

@end

@implementation DeviceListTableViewController

- (void)viewDidLoad {
  if (!_devices) {
    _devices = [[NSMutableArray alloc] init];
  }
  [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [appDelegate.deviceManager addListener:self];
  [appDelegate.deviceManager startScan];
}

- (void)viewWillDisappear:(BOOL)animated {
  [appDelegate.deviceManager removeListener:self];
  [appDelegate.deviceManager stopScan];
  [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return [_devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:@"DeviceCell"];
  }

  const GCKDevice *device = [_devices objectAtIndex:indexPath.row];
  cell.textLabel.text = device.friendlyName;
  cell.detailTextLabel.text = device.ipAddress;

  return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqual:@"CastControls"]) {
    NSIndexPath *selectedIndex = [self.tableView indexPathForSelectedRow];
    GCKDevice *device = [_devices objectAtIndex:selectedIndex.row];
    NSLog(@"selected device is %@", device);
    ((CastViewController *) segue.destinationViewController).device = device;
  }
}

#pragma mark - GCKDeviceManagerListener

- (void)scanStarted {
  NSLog(@"scanStarted");
}

- (void)scanStopped {
  NSLog(@"scanStopped");
}

- (void)deviceDidComeOnline:(GCKDevice *)device {
  [_devices addObject:device];
  [self.tableView reloadData];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
  [_devices removeObject:device];
  [self.tableView reloadData];
}

@end
