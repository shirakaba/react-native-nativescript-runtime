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

## Approach

1. I initialised a React Native plugin using [react-native-builder-bob](https://github.com/callstack/react-native-builder-bob), selecting "Java & Objective-C" as the library type:
    ```sh
    npx create-react-native-library react-native-nativescript-runtime
    ```

2. I manually ran the steps of the [NativeScript Capacitor](https://capacitor.nativescript.org) postinstall script, adjusting them for the structure of a React Native app (and converting Swift into Obj-C where necessary): https://github.com/NativeScript/capacitor/blob/main/src/postinstall.ts

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
