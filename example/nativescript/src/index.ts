// init - keep here.
import 'react-native-nativescript-runtime/lib/module/bridge';

/**
 *      ****       ****
 *      ******     ****
 *      ********   ****
 *    ****** ***** ******  NativeScript
 *      ****   ********
 *      ****     ******
 *      ****       ****
 *
 *    🧠  Learn more:  👉  https://capacitor.nativescript.org/getting-started.html
 */

// Example A: direct native calls
const hello = `👋 🎉 ~ NativeScript Team`;
if (native.isAndroid) {
  console.log(new java.lang.String(`Hello Android ${hello}`));
} else {
  console.log(NSString.alloc().initWithString(`Hello iOS ${hello}`));
}

/**
 * In addition to calling platform iOS and Android api's directly,
 * you can write your own additional helpers here.
 */

// Example B: opening a native modal
import './modalExample';
