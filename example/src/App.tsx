import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
// import NativescriptRuntime from 'react-native-nativescript-runtime/lib/module/plugin/index';
import NativescriptRuntime from '../../lib/module/plugin/index';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  React.useEffect(() => {
    async function callNative() {
      try {
        const multiplyResult = await NativescriptRuntime.multiply(3, 7);
        setResult(multiplyResult);
      } catch (error) {
        console.error(`[React Native] got error`, error);
      }

      try {
        const sumResult = await NativescriptRuntime.postMessage('addNumbers', {
          a: 1,
          b: 2,
        });
        console.log(`[React Native] got sum result`, sumResult);
      } catch (error) {
        console.error(`[React Native] got sum result error`, error);
      }

      try {
        const helloResult = await NativescriptRuntime.postMessage('hello', {
          toWhom: 'world',
        });
        console.log(`[React Native] got hello result`, helloResult);
      } catch (error) {
        console.error(`[React Native] got hello result error`, error);
      }
    }

    callNative();
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
