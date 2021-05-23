import { NativeModules } from 'react-native';

type NativescriptRuntimeType = {
  multiply(a: number, b: number): Promise<number>;
};

const { NativescriptRuntime } = NativeModules;

export default NativescriptRuntime as NativescriptRuntimeType;
