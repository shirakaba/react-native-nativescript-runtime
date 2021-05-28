/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTBridgeDelegate.h>
#import <UIKit/UIKit.h>
// START NativeScript runtime
#import <NativeScript/NativeScript.h>
// END NativeScript runtime

@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate>

@property (nonatomic, strong) UIWindow *window;
// START NativeScript runtime
@property (nonatomic, strong) TNSRuntime *runtime;
// END NativeScript runtime

@end
