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

#import "MediaTableViewController.h"
#import "AppDelegate.h"
#import "Media.h"
#import "MediaList.h"

@implementation MediaTableViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return [appDelegate.mediaList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediaCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:@"MediaCell"];
  }

  const Media *media = [appDelegate.mediaList itemAtIndex:indexPath.row];
  cell.textLabel.text = media.title;
  cell.detailTextLabel.text = media.mimeType;

  BOOL selected = [self.selectedMediaURL isEqual:media.url];
  cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark
      : UITableViewCellAccessoryNone;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  Media *media = [appDelegate.mediaList itemAtIndex:indexPath.row];
  [self.selectionDelegate mediaWasSelected:media];

  [[self navigationController] popViewControllerAnimated:YES];
}

@end
