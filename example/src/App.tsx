import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
// import NativescriptRuntime from 'react-native-nativescript-runtime/lib/module/plugin/index';
import NativescriptRuntime from '../../lib/module/plugin/index';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  React.useEffect(() => {
    NativescriptRuntime.multiply(3, 7).then(setResult);
    NativescriptRuntime.postMessage('hello', { toWhom: 'world' })
      .then((resolution) => {
        console.log(`[React Native] got resolution`, resolution);
      })
      .catch((error) => {
        console.error(`[React Native] got error`, error);
      });
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
