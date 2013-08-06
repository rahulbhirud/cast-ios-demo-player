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

#import "CastViewController.h"

#import <GCKFramework/GCKFramework.h>

#import "AppDelegate.h"
#import "Media.h"
#import "MediaSelectionDelegate.h"
#import "MediaTableViewController.h"

static NSString *kReceiverAppName = @"[YOUR_APP_NAME]";

static NSString *kNoTimeString = @"--:--";

@interface CastViewController () <GCKApplicationSessionDelegate,
    GCKMediaProtocolMessageStreamDelegate, GCKMediaProtocolCommandDelegate,
    GCKNetworkRequestDelegate, MediaSelectionDelegate> {
  GCKApplicationSession *_session;
  GCKMediaProtocolMessageStream *_ramp;
  NSTimer *_timer;
  Media *_selectedMedia;
  GCKFetchImageRequest *_imageRequest;
  BOOL _updatingPosition;
  BOOL _updatingVolume;
  BOOL _resuming;
}

@end

@implementation CastViewController

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"viewDidAppear; selected device is %@", self.device.friendlyName);
  self.title = self.device.friendlyName;

  _timer = [NSTimer scheduledTimerWithTimeInterval:1
                                            target:self
                                          selector:@selector(updateStreamState)
                                          userInfo:nil
                                           repeats:YES];
  [self updateForMediaSelection];
  [self updateButtonStates];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [_timer invalidate];
  _timer = nil;
  [_imageRequest cancel];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqual:@"SelectMedia"]) {
    MediaTableViewController *target = (MediaTableViewController *) segue.destinationViewController;
    target.selectionDelegate = self;
    target.selectedMediaURL = _selectedMedia ? _selectedMedia.url : nil;
  }
}

- (IBAction)castMedia:(id)sender {
  if (!_session || !_session.hasStarted) {
    _session = [[GCKApplicationSession alloc] initWithContext:appDelegate.context
                                                       device:self.device];
    _session.delegate = self;
    [_session startSessionWithApplication:kReceiverAppName argument:nil];
  } else {
    [self playSelectedMedia];
  }
}

- (void)playSelectedMedia {
  if (!_selectedMedia) return;

  GCKContentMetadata *metadata = [[GCKContentMetadata alloc] initWithTitle:_selectedMedia.title
                                                                  imageURL:_selectedMedia.imageURL
                                                               contentInfo:nil];
  GCKMediaProtocolCommand *command =
      [_ramp loadMediaWithContentID:[_selectedMedia.url absoluteString]
                    contentMetadata:metadata
                           autoplay:YES];
  command.delegate = self;
}

- (IBAction)endSession:(id)sender {
  if (!_session) return;

  [_session endSession];
}

- (IBAction)destroySession:(id)sender {
  if (!_session) return;

  [_session endSession];
  _session = nil;
}

- (IBAction)resumeSession:(id)sender {
  if (!_session) return;

  _resuming = YES;
  if (![_session resumeSession]) {
    _resuming = NO;
    [self showError:NSLocalizedString(@"Unable to resume the session.", nil)];
  }
}

- (IBAction)playMedia:(id)sender {
  if (!_ramp) return;

  GCKMediaProtocolCommand *command = [_ramp resumeStream];
  command.delegate = self;
}

- (IBAction)pauseMedia:(id)sender {
  if (!_ramp) return;

  if (![_ramp stopStream]) return;

  [self updateButtonStates];
}

- (IBAction)startDragPosition:(id)sender {
  _updatingPosition = YES;
}

- (IBAction)endDragPosition:(id)sender {
  if (!_ramp) return;

  _updatingPosition = NO;
  NSInteger position = self.streamPositionSlider.value;

  GCKMediaProtocolCommand *command = [_ramp playStreamFrom:(NSTimeInterval)position];
  command.delegate = self;
}

- (IBAction)startDragVolume:(id)sender {
  _updatingVolume = YES;
}

- (IBAction)endDragVolume:(id)sender {
  if (!_ramp) return;

  _updatingVolume = NO;

  NSInteger volume = self.volumeSlider.value;
  GCKMediaProtocolCommand *command = [_ramp setStreamVolume:((double)volume / 100.0)];
  command.delegate = self;
}

- (IBAction)muteToggled:(id)sender {
  if (!_ramp) return;

  BOOL mute = [self.muteSwitch isOn];
  GCKMediaProtocolCommand *command = [_ramp setStreamMuted:mute];
  command.delegate = self;
}

- (void)updateButtonStates {
  BOOL isSessionActive = _session && _session.hasStarted;
  BOOL hasMedia = _selectedMedia != nil;

  [self setButton:self.castButton enabled:hasMedia];
  [self setButton:self.endSessionButton enabled:isSessionActive];
  [self setButton:self.destroySessionButton enabled:isSessionActive];
  [self setButton:self.resumeSessionButton enabled:(_session && !_session.hasStarted)];
  if (_ramp) {
    BOOL playing = (_ramp.playerState == kGCKPlayerStatePlaying);
    [self setButton:self.playButton enabled:!playing];
    [self setButton:self.pauseButton enabled:playing];
    self.streamPositionSlider.enabled = playing;
    self.volumeSlider.enabled = YES;
    self.muteSwitch.enabled = YES;
  } else {
    [self setButton:self.playButton enabled:NO];
    [self setButton:self.pauseButton enabled:NO];
    self.streamPositionSlider.enabled = NO;
    self.volumeSlider.enabled = NO;
    self.muteSwitch.enabled = NO;
  }
}

- (void)setButton:(UIButton *)button
          enabled:(BOOL)enabled {
  button.enabled = enabled;
  button.alpha = enabled ? 1.0 : 0.5;
}

- (void)showError:(NSString *)message {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
}

- (void)updateStreamState {
  if (_ramp) {
    self.streamPositionLabel.text = [self formatTime:_ramp.streamPosition];
    if (!_updatingPosition) {
      self.streamPositionSlider.maximumValue = (NSInteger) _ramp.streamDuration;
      self.streamPositionSlider.value = [_ramp streamPosition];
    }
    if (!_updatingVolume) {
      NSInteger volume = (NSInteger) (_ramp.volume * 100.0);
      self.volumeSlider.value = volume;
      self.muteSwitch.on = _ramp.muted;
    }
    self.streamDurationLabel.text = [self formatTime:_ramp.streamDuration];
  } else {
    self.streamPositionLabel.text = NSLocalizedString(kNoTimeString, nil);
    self.streamPositionSlider.maximumValue = 1;
    self.streamPositionSlider.value = 0;
    self.streamDurationLabel.text = NSLocalizedString(kNoTimeString, nil);
  }
}

- (void)updateForMediaSelection {
  if (_selectedMedia) {
    self.currentMediaLabel.text = _selectedMedia.title;
    self.currentMediaArtistLabel.text = _selectedMedia.artist;
    if (_selectedMedia.imageURL) {
      if (_imageRequest) {
        [_imageRequest cancel];
      }
      _imageRequest = [[GCKFetchImageRequest alloc]
                       initWithContext:appDelegate.context
                                   url:_selectedMedia.imageURL
                        preferredWidth:self.imageView.frame.size.width
                        preferredHeight:self.imageView.frame.size.height];
      _imageRequest.delegate = self;
      [_imageRequest execute];
    } else {
      self.imageView.image = nil;
    }
  } else {
    self.currentMediaLabel.text = NSLocalizedString(@"(No Media Selected)", nil);
    self.currentMediaArtistLabel.text = nil;
    self.imageView.image = nil;
  }
}

- (NSString *)formatTime:(NSInteger)seconds {
  NSInteger hours = seconds / (60 * 60);
  seconds %= (60 * 60);

  NSInteger minutes = seconds / 60;
  seconds %= 60;

  if (hours > 0) {
    return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
  } else {
    return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
  }
}

#pragma mark - GCKApplicationSessionDelegate

- (void)applicationSessionDidStart {
  NSLog(@"session has started");

  _ramp = [[GCKMediaProtocolMessageStream alloc] init];
  _ramp.delegate = self;

  GCKApplicationChannel *channel = _session.channel;
  [channel attachMessageStream:_ramp];

  if(!_resuming) {
    [self playSelectedMedia];
  }
  _resuming = NO;
  [self updateButtonStates];
}

- (void)applicationSessionDidFailToStartWithError:(GCKApplicationSessionError *)error {
  _resuming = NO;
  [self updateButtonStates];
  [self showError:[error localizedDescription]];
}

- (void)applicationSessionDidEndWithError:(GCKApplicationSessionError *)error {
  _ramp = nil;
  [self updateButtonStates];

  if (error != nil) {
    [self showError:[error localizedDescription]];
  }
}

#pragma mark - GCKMediaProtocolMessageStreamDelegate

- (void)mediaProtocolMessageStreamDidReceiveStatusUpdate:(GCKMediaProtocolMessageStream *)stream {
  [self updateButtonStates];
  [self updateStreamState];
}

- (void)mediaProtocolMessageStream:(GCKMediaProtocolMessageStream *)stream
         didReceiveErrorWithDomain:(NSString *)domain
                              code:(NSInteger)code {
  [self showError:NSLocalizedString(@"RAMP stream received an error.", nil)];
}

#pragma mark - GCKMediaProtocolCommandDelegate

- (void)mediaProtocolCommandDidComplete:(GCKMediaProtocolCommand *)command {
  if (command.hasError) {
    NSString *message = [NSString stringWithFormat:@"RAMP %@ command failed.", command.type];
    [self showError:message];
    NSLog(@"RAMP command %@ failed: %@/%d.", command.type, command.errorDomain, command.errorCode);
  } else {
    NSLog(@"RAMP command %@ completed.", command.type);
  }
}

- (void)mediaProtocolCommandWasCancelled:(GCKMediaProtocolCommand *)command {
  NSLog(@"RAMP command cancelled: %@", command.type);
}

#pragma mark - GCKNetworkRequestDelegate

- (void)networkRequest:(GCKNetworkRequest *)request
      didFailWithError:(GCKNetworkRequestError *)error {
  NSLog(@"Failed to fetch image: %@", error.localizedDescription);
  self.imageView.image = nil;
  _imageRequest = nil;
}

- (void)networkRequestDidComplete:(GCKNetworkRequest *)request {
  GCKFetchImageRequest *imageRequest = (GCKFetchImageRequest *)request;
  UIImage *image = imageRequest.image;
  self.imageView.image = image;
  _imageRequest = nil;
}

- (void)networkRequestWasCancelled:(GCKNetworkRequest *)request {
  if (request == _imageRequest) {
    _imageRequest = nil;
  }
}

#pragma mark - MediaSelectionDelegate

- (void)mediaWasSelected:(Media *)media {
  NSLog(@"media was selected: %@", media.title);
  _selectedMedia = media;
  [self updateForMediaSelection];
}

@end
