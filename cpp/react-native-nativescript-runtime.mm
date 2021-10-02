#import "react-native-nativescript-runtime.h"
#import "JSIUtils.h"

#include <iostream>
#include <functional>
#include <sstream>

using namespace facebook;

// In C++, the equivalent would be: std::function<void(jsi::Value*)>>
typedef id (^NativeScriptRuntimeCallbackType)(jsi::Object payload);

namespace ReactNativeNativeScriptRuntime {
// @see https://github.com/ospfranco/react-native-jsi-template
// @see https://ospfranco.com/post/2021/02/24/how-to-create-a-javascript-jsi-module/
// @see https://github.com/facebook/react-native/blob/main/ReactCommon/jsi/jsi/jsi.cpp
// @see https://github.com/ammarahm-ed/react-native-simple-jsi/blob/master/cpp/example.cpp
// @see https://blog.notesnook.com/getting-started-react-native-jsi/
void install(jsi::Runtime& jsiRuntime) {
  std::cout << "Initialising NativeScript JSI" << "\n";
  if (gNativeScriptHandlers) {
    std::cout << "Warning: ReactNativeNativeScriptRuntime::install() called redundantly. No-op." << "\n";
    return;
  }
  
  ReactNativeNativeScriptRuntimeInitialiseNativeScriptHandlers();

  auto postMessageToNativeScript = jsi::Function::createFromHostFunction(
    jsiRuntime,
    jsi::PropNameID::forAscii(jsiRuntime, "postMessageToNativeScript"),
    2,
    [](jsi::Runtime& runtime, const jsi::Value& thisValue, const jsi::Value* arguments, size_t count) -> jsi::Value {
      if (count != 2) {
        jsi::detail::throwJSError(runtime, "Expected exactly two arguments.");
      }

      if (!arguments[0].isString()) {
        jsi::detail::throwJSError(runtime, "Expected first argument to be a string.");
      }

      if (!arguments[1].isObject()) {
        jsi::detail::throwJSError(runtime, "Expected second argument to be an object.");
      }
      
      // TODO: based on the first argument, select the message handler. For now, we always call handleMessage.
      // That said, we could live with just handleMessage alone.
//      if (!runtime.strictEquals(arguments[0].getString(runtime), jsi::Value("handleMessage"))){
//        jsi::detail::throwJSError(runtime, "Expected the first argument to strictly equal 'handleMessage'");
//      }
      
      NativeScriptRuntimeCallbackType callback = [gNativeScriptHandlers objectForKey:@"handleMessage"];
      id rawReturnValue = callback(arguments[1].getObject(runtime));
      jsi::Value jsiValue = convertObjCObjectToJSIValue(runtime, rawReturnValue);
      
      return jsiValue;
    }
  );

  jsiRuntime.global().setProperty(jsiRuntime, "postMessageToNativeScript", std::move(postMessageToNativeScript));
}

void uninstall(jsi::Runtime& jsiRuntime) {
  gNativeScriptHandlers = nil;
  // We seemingly can't remove the property altogether, but let's at least try to set it to undefined.
  jsiRuntime.global().setProperty(jsiRuntime, "postMessageToNativeScript", jsi::Value::undefined());
}
} // namespace example
