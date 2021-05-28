# react-native-nativescript-runtime

Use the NativeScript runtime in a React Native app!

## Project status

Still a work-in-progress. See the TODO section at the bottom of the Readme for current progress.

In short: We are not *yet* running NativeScript code in React Native. However, we **do** have a script to automatically integrate the NativeScript library set up in a React Native iOS project. I've not paid much attention to Android at all, yet.

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

## Contributing

I'll explain the repo structure.

### Repo architecture

This repo was initialised using the standard [react-native-builder-bob](https://github.com/callstack/react-native-builder-bob) tool, which bootstraps a best-practice boilerplate for making a React Native plugin (whilst also testing it on an example app).

To get an impression of what changes I've made beyond initialising the repo, see the next section where I provide a diff.

To understand what the purpose of this labyrinth of folders is, see my notes below.

Things to keep in mind:

* This React Native plugin, like most React Native plugins, will be distributed as an npm package that itself vends a locally-built CocoaPod and a locally-built Gradle file. Those locally-built native modules can make use of all the files that the npm package includes.
* The example app lives at `/example`
* The iOS native sources live at `/ios`
* The Android native sources live at `/android`
* Any directory can be pulled into the npm package, e.g. `/scripts`, for use by the iOS and/or Android native modules.
* Conversely, the iOS and/or Android native modules can choose to exclude some of the files in their directories (this is appropriate when we have e.g. an iOS-specific resource like `XCFrameworks.zip` that we want to simply unzip into the root of the app, rather than bundle into it as-is).


```yaml
.
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── android # The React Native Android native module.
│   ├── build.gradle
│   └── src
│   └── main
│       ├── AndroidManifest.xml
│       └── java
│           └── com
│               └── reactnativenativescriptruntime
│                   ├── NativescriptRuntimeModule.java
│                   └── NativescriptRuntimePackage.java
├── babel.config.js # The Babel config for all TSX?/JSX? sources excluding `/example`, which has its own Babel config.
├── example # The folder for the example app. Unlike the convention in NativeScript, it is source-controlled.
│   ├── android # The Android example app. I haven't done much work on it yet.
│   │   ├── app
│   │   ├── build.gradle
│   │   ├── gradle
│   │   ├── gradle.properties
│   │   ├── gradlew
│   │   ├── gradlew.bat
│   │   ├── nativescript.build.gradle
│   │   ├── nativescript.buildscript.gradle
│   │   └── settings.gradle
│   ├── app.json # The React Native example app's metadata (display name, etc). I think this is an Expo concept.
│   ├── babel.config.js # The React Native example app's Babel config.
│   ├── index.tsx # The React Native example app's entrypoint.
│   ├── ios # The iOS example app.
│   │   ├── File.swift
│   │   ├── NativeScript # This is copied from the `ios` folder vended by the npm package.
│   │   ├── NativeScript.xcframework # This is unzipped from the `ios/XCFrameworks.zip` folder vended by the npm package.
│   │   ├── NativescriptRuntimeExample
│   │   ├── NativescriptRuntimeExample-Bridging-Header.h
│   │   ├── NativescriptRuntimeExample.xcodeproj
│   │   ├── NativescriptRuntimeExample.xcworkspace
│   │   ├── Podfile # The Podfile for the iOS app. Calls upon use_nativescript.rb.
│   │   ├── Podfile.lock
│   │   ├── Pods
│   │   ├── TNSWidgets.xcframework # This is unzipped from the `ios/XCFrameworks.zip` folder vended by the npm package.
│   │   ├── __MACOSX
│   │   ├── internal # This is copied from @nativescript/ios.
│   │   └── use_nativescript.rb # The script to install NativeScript. Once finalised, I plan to move this logic into:
|                               # /react-native-nativescript-runtime.podspec, or;
|                               # /scripts/use_nativescript.rb.
│   ├── metro.config.js # The bundler config for the React Native example app.
│   ├── nativescript
│   ├── node_modules
│   ├── package-lock.json
│   ├── package.json 
│   └── src # The sources for the React Native example app.
|           # I'm debating whether or not to nest the NativeScript sources in src/nativescript.
|           # It's not clear what would be more intuitive in a React Native project.
├── ios # The React Native iOS native module.
│   ├── NativeScript # Copied from @nativescript/capacitor. Originally from @nativescript/ui-mobile-base.
│   │   ├── App-Bridging-Header.h
│   │   ├── Runtime.h
│   │   └── Runtime.m
│   ├── NativescriptRuntime.h # React Native iOS native module header. Not yet filled in.
│   ├── NativescriptRuntime.m # React Native iOS native module implementation. Not yet filled in.
│   ├── NativescriptRuntime.xcodeproj # React Native iOS native module xcodeproj.
│   └── XCFrameworks.zip # Copied from @nativescript/capacitor. Not the same as the one in @nativescript/ios.
├── package.json # When publishing this module to npm, it'll be from the root of the repo, using this.
├── react-native-nativescript-runtime.podspec # Specifies any native iOS files to be included in the CocoaPod.
├── scripts # Scripts to be used by both the npm package and (if necessary) the native modules.
│   ├── bootstrap.js
│   ├── build-nativescript.js
│   └── extractFrameworks.js
├── src # This is where you write the TypeScript API corresponding to your native module.
│   ├── __tests__
│   └── index.tsx
├── tsconfig.build.json # This examines all TypeScript sources excluding the example app, `/example`.
└── tsconfig.json
```

### Changes relative to a freshly initialised React Native plugin

Here is a tree of changes I've made, relative to a freshly initialised [react-native-builder-bob](https://github.com/callstack/react-native-builder-bob) plugin. Note that this is **very approximate**, as things are changing rapidly from commit to commmit and I may simply miss some things. But it should at least give a general orientation as to what's specific to this plugin rather than just being typical React Native plugin boilerplate.

* In green are the files that I either committed to the repo as sources, or will be auto-provisioned upon building the project (e.g. due to the `use_nativescript.rb` iOS installer script, which is equivalent to the `postinstall.ts` script in the NativeScript Capacitor repo).
* Marked with an asterisk are any files that I've modified (again, either committed to source or post-build).

⚠️ Beware that I've not actually committed the Android aspects yet, but eventually they'll be shaped like this.

```diff
.
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── android
│   ├── build.gradle *
│   └── src
│       └── main
├── babel.config.js
├── example
│   ├── android
│   │   ├── app
│   │   │   ├── build.gradle *
│   │   │   ├── debug.keystore
│   │   │   ├── proguard-rules.pro
│   │   │   └── src
│   │   │       └── main
│   │   │           └── AndroidManifest.xml *
│   │   ├── build.gradle *
│   │   ├── gradle
│   │   ├── gradle.properties
│   │   ├── gradlew
│   │   ├── gradlew.bat
+ │   │   ├── nativescript.build.gradle
+ │   │   ├── nativescript.buildscript.gradle
│   │   └── settings.gradle
│   ├── app.json
│   ├── babel.config.js
│   ├── index.tsx
│   ├── ios
│   │   ├── File.swift
+ │   │   ├── NativeScript
+ │   │   ├── NativeScript.xcframework
│   │   ├── NativescriptRuntimeExample
│   │   ├── NativescriptRuntimeExample-Bridging-Header.h
│   │   ├── NativescriptRuntimeExample.xcodeproj *
│   │   ├── NativescriptRuntimeExample.xcworkspace
│   │   ├── Podfile *
│   │   ├── Podfile.lock *
│   │   ├── Pods
+ │   │   ├── TNSWidgets.xcframework
+ │   │   ├── __MACOSX
+ │   │   ├── internal
+ │   │   └── use_nativescript.rb
│   ├── metro.config.js
+ │   ├── nativescript
+ │   │   ├── build
+ │   │   ├── package.json
+ │   │   ├── references.d.ts
+ │   │   ├── src
+ │   │   └── tsconfig.json
│   ├── node_modules
│   ├── package-lock.json *
│   ├── package.json *
│   └── src
│       └── App.tsx
├── ios
+ │   ├── NativeScript
+ │   │   ├── App-Bridging-Header.h
+ │   │   ├── Runtime.h
+ │   │   └── Runtime.m
│   ├── NativescriptRuntime.h
│   ├── NativescriptRuntime.m
│   ├── NativescriptRuntime.xcodeproj
│   │   ├── project.pbxproj
│   │   └── project.xcworkspace
+ │   └── XCFrameworks.zip
├── package.json
├── react-native-nativescript-runtime.podspec
├── scripts
│   ├── bootstrap.js
+ │   └── build-nativescript.js
├── src
│   ├── __tests__
│   │   └── index.test.tsx
│   └── index.tsx
├── tsconfig.build.json
└── tsconfig.json
```

## TODO

### Android

Unscoped. So far I've manually copied over (but have so far chosen not to commit) the file changes that NativeScript Capacitor made to a vanilla Capacitor app. I've not automated anything.

### iOS

Auto-provisioning of the Xcode project is complete. Some steps remain manual for now.

- [ ] [Swift support] Allow (or simply instruct) users how to use their own bridging header
- [ ] [Swift support] Support `AppDelegate.swift`
- [ ] Support auto-injection of runtime support into `AppDelegate.{m,swift}` (see the code blocks surrounded by `// START NativeScript runtime` and `// END NativeScript runtime`), or just give instructions.
- [ ] Support uninstallation of NativeScript runtime support.

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
