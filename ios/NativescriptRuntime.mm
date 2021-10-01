#import <React/RCTBridge+Private.h>
#import <React/RCTConvert.h>
#import "NativescriptRuntime.h"
#import "../cpp/react-native-nativescript-runtime.h"

@implementation NativescriptRuntime

@synthesize bridge=_bridge;

// Module NativescriptRuntime requires main queue setup since it overrides `init` but doesn't implement `requiresMainQueueSetup`.
// In a future release React Native will default to initializing all native modules on a background thread unless explicitly opted-out of.
+ (BOOL)requiresMainQueueSetup {
  return YES;
}

- (instancetype)init
{
  if ((self = [super init])) {
    self.messageCount = 0;
    self.pendingMessages = [[NSMutableDictionary alloc] init];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onResponse:) name:@"NativeScriptBridgeResponse" object:nil];
  }
  return self;
}

- (void)onResponse:(NSNotification *) notification
{
  NSLog(@"Got response!%@", notification.name);
  NSString* errorLogPrefix = @"Error handling NativeScript Bridge response:";
  if(!notification.userInfo){
    RCTLogWarn(@"%@", [NSString stringWithFormat:@"%@ Missing userInfo from notification.", errorLogPrefix]);
    return;
  }
  NSString* messageId = [notification.userInfo valueForKey:@"id"];
  if(!messageId){
    RCTLogWarn(@"%@", [NSString stringWithFormat:@"%@ Missing message id from notification.", errorLogPrefix]);
    return;
  }
  NSDictionary* handlers = [self.pendingMessages valueForKey:messageId];
  if(!handlers){
    RCTLogWarn(@"%@", [NSString stringWithFormat:@"%@ Message id %@ not recognised.", messageId, errorLogPrefix]);
    return;
  }
  RCTPromiseResolveBlock resolve = [handlers valueForKey:@"resolve"];
  if(!resolve){
    RCTLogWarn(@"%@", [NSString stringWithFormat:@"%@ Missing resolve handler for message id %@.", messageId, errorLogPrefix]);
    return;
  }
  RCTPromiseRejectBlock reject = [handlers valueForKey:@"reject"];
  if(!reject){
    RCTLogWarn(@"%@", [NSString stringWithFormat:@"%@ Missing reject handler for message id %@.", messageId, errorLogPrefix]);
    return;
  }
  NSString* responseType = [notification.userInfo valueForKey:@"responseType"];
  if(!responseType){
    RCTLogWarn(@"%@", [NSString stringWithFormat:@"%@ Missing response type on message id %@.", messageId, errorLogPrefix]);
    return;
  }
  
  if([responseType isEqualToString:@"resolve"]){
    id resolveArg = [notification.userInfo valueForKey:@"resolveArg"];
    // TODO: check how this handles undefined. i.e. do we need to coalesce it to NSNull?
    resolve(resolveArg);
    [self.pendingMessages removeObjectForKey:messageId];
    return;
  } else if([responseType isEqualToString:@"reject"]){
    NSArray* rejectArgs = [notification.userInfo valueForKey:@"resolveArgs"];
    reject(rejectArgs[0], rejectArgs[1], rejectArgs[2]);
    [self.pendingMessages removeObjectForKey:messageId];
    return;
  } else {
    RCTLogWarn(@"%@", [NSString stringWithFormat:@"%@ Invalid response type, %@.", errorLogPrefix, responseType]);
    return;
  }
  
}

// Because we declared the setBridgeOnMainQueue property on our module, React Native will
// implicitly call [setBridge bridge].
// @see https://blog.notesnook.com/getting-started-react-native-jsi/
// TODO: figure out what the right TS typings will be for this module. Whether it's a global call or module one.
- (void)setBridge:(RCTBridge *)bridge {
  _bridge = bridge;
  _setBridgeOnMainQueue = RCTIsMainQueue();

  RCTCxxBridge *cxxBridge = (RCTCxxBridge *)self.bridge;
  if (!cxxBridge.runtime) {
    return;
  }
  
  ReactNativeNativeScriptRuntime::install(*(facebook::jsi::Runtime *)cxxBridge.runtime);
}

// Again, another magic method name?
// Got it from Oscar's example.
- (void)invalidate {
  if(!self.bridge){
    return;
  }
  RCTCxxBridge *cxxBridge = (RCTCxxBridge *)self.bridge;
  if (!cxxBridge.runtime) {
    return;
  }
  ReactNativeNativeScriptRuntime::uninstall(*(facebook::jsi::Runtime *)cxxBridge.runtime);
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Below this are some classic bridge APIs. We may keep them around for performance comparisons.

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
  self.messageCount++;
  
  NSString* messageId = [NSString stringWithFormat:@"%d", self.messageCount];
 
  [self.pendingMessages
   setValue:[
             [NSDictionary alloc]
             initWithObjectsAndKeys:
             resolve, @"resolve",
             reject, @"reject",
             nil
            ]
   forKey:messageId
  ];
  
  [NSNotificationCenter.defaultCenter
   postNotificationName:@"NativeScriptBridgeRequest"
   object:self
   userInfo:[
             [NSDictionary alloc]
             initWithObjectsAndKeys:
             name, @"name",
             messageId, @"id",
             payload ?: [NSNull null], @"payload",
             nil
            ]
  ];
}

@end
