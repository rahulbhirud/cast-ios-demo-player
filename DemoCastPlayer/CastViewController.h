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

#import <UIKit/UIKit.h>

#import <GCKFramework/GCKFramework.h>

@interface CastViewController : UIViewController

@property (nonatomic, strong) GCKDevice *device;

@property (nonatomic) IBOutlet UILabel *currentMediaLabel;
@property (nonatomic) IBOutlet UILabel *currentMediaArtistLabel;
@property (nonatomic) IBOutlet UILabel *streamPositionLabel;
@property (nonatomic) IBOutlet UILabel *streamDurationLabel;
@property (nonatomic) IBOutlet UISlider *streamPositionSlider;
@property (nonatomic) IBOutlet UIButton *castButton;
@property (nonatomic) IBOutlet UIButton *endSessionButton;
@property (nonatomic) IBOutlet UIButton *destroySessionButton;
@property (nonatomic) IBOutlet UIButton *resumeSessionButton;
@property (nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) IBOutlet UIButton *pauseButton;
@property (nonatomic) IBOutlet UISlider *volumeSlider;
@property (nonatomic) IBOutlet UISwitch *muteSwitch;
@property (nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)castMedia:(id)sender;
- (IBAction)endSession:(id)sender;
- (IBAction)destroySession:(id)sender;
- (IBAction)resumeSession:(id)sender;
- (IBAction)playMedia:(id)sender;
- (IBAction)pauseMedia:(id)sender;
- (IBAction)startDragPosition:(id)sender;
- (IBAction)endDragPosition:(id)sender;
- (IBAction)startDragVolume:(id)sender;
- (IBAction)endDragVolume:(id)sender;
- (IBAction)muteToggled:(id)sender;

@end
