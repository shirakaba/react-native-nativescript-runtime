#ifndef REACT_NATIVE_NATIVESCRIPT_RUNTIME_H
#define REACT_NATIVE_NATIVESCRIPT_RUNTIME_H

#import "../ios/gNativeScriptHandlers.h"
#include <jsi/jsilib.h>
#include <jsi/jsi.h>

namespace ReactNativeNativeScriptRuntime {

void install(facebook::jsi::Runtime &jsiRuntime);
void uninstall(facebook::jsi::Runtime &jsiRuntime);

} // namespace example

#endif /* REACT_NATIVE_NATIVESCRIPT_RUNTIME_H */
