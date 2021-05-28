# react-native-nativescript-runtime

Use the NativeScript runtime in a React Native app!

## Installation

```sh
npm install react-native-nativescript-runtime
```

## Usage

```js
import NativescriptRuntime from "react-native-nativescript-runtime";

// ...

const result = await NativescriptRuntime.multiply(3, 7);
```

## TODO

### Android

Unscoped. So far I've manually copied over (but have so far chosen not to commit) the file changes that NativeScript Capacitor made to a vanilla Capacitor app. I've not automated anything.

### iOS

Auto-provisioning of the Xcode project is complete. Some steps remain manual for now.

[ ] [Swift support] Allow (or simply instruct) users how to use their own bridging header
[ ] [Swift support] Support `AppDelegate.swift`
[ ] Support auto-injection of runtime support into `AppDelegate.{m,swift}` (see the code blocks surrounded by `// START NativeScript runtime` and `// END NativeScript runtime`), or just give instructions.
[ ] Support uninstallation of NativeScript runtime support.

### TS/JS

Figure out how to make NativeScript bundle (see `scripts/build-nativescript.js`).

### Calling NativeScript from React Native

Build an API for sending messages to the NativeScript runtime from the React Native JS context. i.e. make a React Native native module under `/ios` and `/android`, with reference to the Capacitor one.

## Approach

1. I initialised a React Native plugin using [react-native-builder-bob](https://github.com/callstack/react-native-builder-bob), selecting "Java & Objective-C" as the library type:
    ```sh
    npx create-react-native-library react-native-nativescript-runtime
    ```

2. I ported the [NativeScript Capacitor](https://capacitor.nativescript.org) postinstall script to Ruby (see `example/ios/use_nativescript.rb`), adjusting it for the structure of a React Native app: https://github.com/NativeScript/capacitor/blob/main/src/postinstall.ts

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
