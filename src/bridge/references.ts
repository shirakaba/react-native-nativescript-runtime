/// <reference types="@nativescript/core/global-types" />
/// <reference types="@nativescript/types-ios" />
/// <reference types="@nativescript/types-android/lib/android-30" />

declare module NodeJS {
  interface Global {
    native?: NodeJS.Global & typeof globalThis;
    androidCapacitorActivity: android.app.Activity;
  }
}
