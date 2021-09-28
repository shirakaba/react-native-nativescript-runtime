/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "AppDelegate.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#ifdef FB_SONARKIT_ENABLED
#import <FlipperKit/FlipperClient.h>
#import <FlipperKitLayoutPlugin/FlipperKitLayoutPlugin.h>
#import <FlipperKitUserDefaultsPlugin/FKUserDefaultsPlugin.h>
#import <FlipperKitNetworkPlugin/FlipperKitNetworkPlugin.h>
#import <SKIOSNetworkPlugin/SKIOSNetworkAdapter.h>
#import <FlipperKitReactPlugin/FlipperKitReactPlugin.h>
static void InitializeFlipper(UIApplication *application) {
  FlipperClient *client = [FlipperClient sharedClient];
  SKDescriptorMapper *layoutDescriptorMapper = [[SKDescriptorMapper alloc] initWithDefaults];
  [client addPlugin:[[FlipperKitLayoutPlugin alloc] initWithRootNode:application withDescriptorMapper:layoutDescriptorMapper]];
  [client addPlugin:[[FKUserDefaultsPlugin alloc] initWithSuiteName:nil]];
  [client addPlugin:[FlipperKitReactPlugin new]];
  [client addPlugin:[[FlipperKitNetworkPlugin alloc] initWithNetworkAdapter:[SKIOSNetworkAdapter new]]];
  [client start];
}
#endif

// START NativeScript runtime
#import "Runtime.h"
#import "NativeScript/NativeScript.h"
// END NativeScript runtime

NSMutableDictionary* gNativeScriptHandlers = nil;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // START NativeScript runtime
  void *pointer = runtimeMeta();
  [TNSRuntime initializeMetadata:pointer];
  self.runtime = [[TNSRuntime alloc] initWithApplicationPath:[[NSBundle mainBundle] bundlePath]];
  // Path is implicitly relative to a folder "app" in the root of the built NativescriptRuntimeExample.app product.
  // nativescript-bundle.js is copied into the root of NativescriptRuntimeExample.app, so we have to step up by one directory to satisfy the path lookup.
  [self.runtime executeModule:@"../nativescript-bundle.js"];
  // TODO: Expose it to the global so that our JSI module can access it from the C++ context.
  gNativeScriptHandlers = [[NSMutableDictionary alloc] init];
  [gNativeScriptHandlers setValue:@"123" forKey: @"foo"];
  
  // @see https://github.com/NativeScript/ios-runtime/blob/master/examples/BlankApp/main.m#L41
  // @see https://stackoverflow.com/questions/30101366/converting-a-jsglobalcontextref-to-a-jscontext
  // END NativeScript runtime
  
  #ifdef FB_SONARKIT_ENABLED
    InitializeFlipper(application);
  #endif
  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                   moduleName:@"NativescriptRuntimeExample"
                                            initialProperties:nil];

  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
