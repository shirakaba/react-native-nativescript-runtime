#import "./gNativeScriptHandlers.h"

NSMutableDictionary* gNativeScriptHandlers = nil;

void ReactNativeNativeScriptRuntimeInitialiseNativeScriptHandlers() {
  if (gNativeScriptHandlers) {
    NSLog(@"Warning: ReactNativeNativeScriptRuntimeInitialiseNativeScriptHandlers() called redundantly. No-op.");
    return;
  }
  gNativeScriptHandlers = [[NSMutableDictionary alloc] init];
}
