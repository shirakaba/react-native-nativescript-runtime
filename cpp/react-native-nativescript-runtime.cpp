#import "react-native-nativescript-runtime.h"

#include <iostream>
#include <sstream>

using namespace facebook;

// @see https://github.com/ospfranco/react-native-jsi-template
// @see https://ospfranco.com/post/2021/02/24/how-to-create-a-javascript-jsi-module/
// @see https://github.com/facebook/react-native/blob/main/ReactCommon/jsi/jsi/jsi.cpp
void installNativeScriptJSI(jsi::Runtime& jsiRuntime) {
  std::cout << "Initialising NativeScript JSI" << "\n";

  auto postMessageToNativeScript = jsi::Function::createFromHostFunction(
    jsiRuntime,
    jsi::PropNameID::forAscii(jsiRuntime, "postMessageToNativeScript"),
    1,
    [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
      if (!count != 2) {
        jsi::detail::throwJSError(runtime, "Expected exactly two arguments.");
      }

      if (!arguments[0].isString()) {
        jsi::detail::throwJSError(runtime, "Expected first argument to be a string.");
      }

      if (!arguments[1].isObject()) {
        jsi::detail::throwJSError(runtime, "Expected second argument to be an object.");
      }

      // TODO: actually post a message to NativeScript.
      // Right now we're in C++ land.
      // If, in AppDelegate.m, we could expose our NativeScript JSC instance to the C++ runtime
      // (perhaps by making an 'extern' variable?), then we'd 'just' need to call something like:
      //   jscInstance.executeJavaScript(`nativeScriptMessageHandler(${arguments[0]}, ${arguments[1]})`);
      // ... assuming that the NativeScript side has set up a global function called nativeScriptMessageHandler().
      // Worries include JSON escaping and string conversion (UTF-16 preservation).

      // double res = 42;
      // // return jsi::Value(arguments[0].asNumber(runtime) * arguments[1].asNumber(runtime));
      // return jsi::Value(res);
    }
  );

  jsiRuntime.global().setProperty(jsiRuntime, "postMessageToNativeScript", std::move(postMessageToNativeScript));
}

void cleanUpNativeScriptJSI() {
  // TODO: remove 'postMessageToNativeScript' from jsiRuntime global.
}
