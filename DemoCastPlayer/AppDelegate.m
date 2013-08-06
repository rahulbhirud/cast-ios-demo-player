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

#import "AppDelegate.h"
#import "MediaList.h"

@interface AppDelegate ()

@property(nonatomic, strong, readwrite) GCKContext *context;
@property(nonatomic, strong, readwrite) GCKDeviceManager *deviceManager;
@property(nonatomic, strong, readwrite) MediaList *mediaList;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.context = [[GCKContext alloc] initWithUserAgent:@"DemoCastPlayer"];
  self.deviceManager = [[GCKDeviceManager alloc] initWithContext:self.context];

  [self loadMediaList];

  return YES;
}

- (void)loadMediaList {
  NSString *xmlFile = [[NSBundle mainBundle] pathForResource:@"media" ofType:@"xml"];
  self.mediaList = [[MediaList alloc] initWithPath:xmlFile];
  if ([self.mediaList load]) {
    NSLog(@"loaded %d media items", [self.mediaList count]);
  } else {
    NSLog(@"failed to load media list");
  }
}

@end
