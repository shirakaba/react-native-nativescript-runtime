#ifndef REACT_NATIVE_NATIVESCRIPT_RUNTIME_H
#define REACT_NATIVE_NATIVESCRIPT_RUNTIME_H

// We could swap out Foundation's NSDictionary with Core Foundation's CFDictionary,
// (which is compatible with C++, meaning that this wouldn't have to be Obj-C++.
// However, the APIs are far more awkward (at both points of use – when initialising
// it natively in AppDelegate.m and when mutating it from NativeScript).
// It also doesn't decouple us from Apple SDKs (we'll still need to duplicate this
// logic for Android), so it doesn't bring any real benefit.
#include <Foundation/Foundation.h>
#include <jsi/jsilib.h>
#include <jsi/jsi.h>

// This will be null until AppDelegate.m assigns it.
// The moment it is assigned, it is ready to be called upon.
extern NSMutableDictionary *gNativeScriptHandlers;

namespace ReactNativeNativeScriptRuntime {

void install(facebook::jsi::Runtime &jsiRuntime);
void uninstall(facebook::jsi::Runtime &jsiRuntime);

} // namespace example

#endif /* REACT_NATIVE_NATIVESCRIPT_RUNTIME_H */
