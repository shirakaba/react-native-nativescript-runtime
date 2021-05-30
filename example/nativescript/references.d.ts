/// <reference types="@nativescript/core/global-types" />
/// <reference types="@nativescript/types-ios" />
/// <reference types="@nativescript/types-android/lib/android-30" />

import type { nativeCustom } from '../native-custom';

declare global {
  var androidCapacitorActivity: android.app.Activity;
  var native: NodeJS.Global & typeof globalThis & nativeCustom;
}
