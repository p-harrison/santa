/// Copyright 2023 Google LLC
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     https://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

#import "Source/gui/SNTFileAccessMessageWindowController.h"
#import "Source/gui/SNTFileAccessMessageWindowView-Swift.h"

#import "Source/common/SNTBlockMessage.h"
#import "Source/common/SNTFileAccessEvent.h"
#import "Source/common/SNTLogging.h"

@interface SNTFileAccessMessageWindowController ()
@property NSString *customMessage;
@property SNTFileAccessEvent *event;
@end

@implementation SNTFileAccessMessageWindowController

- (instancetype)initWithEvent:(SNTFileAccessEvent *)event customMsg:(nullable NSString *)message {
  self = [super init];
  if (self) {
    _customMessage = message;
    _event = event;
  }
  return self;
}

- (void)showWindow:(id)sender {
  if (self.window) {
    [self.window orderOut:sender];
  }

  self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0)
                                            styleMask:NSWindowStyleMaskBorderless
                                              backing:NSBackingStoreBuffered
                                                defer:NO];

  self.window.contentViewController = [SNTFileAccessMessageWindowViewFactory
    createWithWindow:self.window
               event:self.event
           customMsg:self.attributedCustomMessage
     uiStateCallback:^(BOOL preventNotificationsForADay) {
       self.silenceFutureNotifications = preventNotificationsForADay;
     }];

  self.window.delegate = self;

  // Make sure app doesn't appear in Cmd+Tab or Dock.
  NSApp.activationPolicy = NSApplicationActivationPolicyAccessory;

  [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification {
  // Remove app from Cmd+Tab and Dock.
  NSApp.activationPolicy = NSApplicationActivationPolicyAccessory;
  [super windowWillClose:notification];
}

- (NSAttributedString *)attributedCustomMessage {
  return [SNTBlockMessage attributedBlockMessageForFileAccessEvent:self.event
                                                     customMessage:self.customMessage];
}

- (NSString *)messageHash {
  // The hash for display de-duplication/silencing purposes is a combination of:
  // 1. The current file access rule version
  // 2. The name of the rule that was violated
  // 3. The path of the process
  return [NSString
    stringWithFormat:@"%@|%@|%@", self.event.ruleVersion, self.event.ruleName, self.event.filePath];
}

@end
