#import "NativescriptRuntime.h"

@implementation NativescriptRuntime

RCT_EXPORT_MODULE()

// Example method
// See // https://reactnative.dev/docs/native-modules-ios
RCT_REMAP_METHOD(multiply,
                 multiplyWithA:(nonnull NSNumber*)a withB:(nonnull NSNumber*)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
  NSNumber *result = @([a floatValue] * [b floatValue]);

  resolve(result);
}

// Example method
// See https://reactnative.dev/docs/native-modules-ios
// See https://reactnative.dev/docs/native-modules-ios#argument-types
RCT_REMAP_METHOD(postMessage,
                 postMessageName:(nonnull NSString*)name payload:(nullable id)payload
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
  [NSNotificationCenter.defaultCenter
   postNotificationName:@"NativeScriptBridge"
   object:self
   userInfo:[
             [NSDictionary alloc]
             initWithObjectsAndKeys:
             name, @"name",
             payload ?: [NSNull null], @"payload",
             resolve, @"resolve",
             reject, @"reject",
             nil
            ]
  ];
}

@end
