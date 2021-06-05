import { NativeModules } from 'react-native';

type NativescriptRuntimeType = {
  multiply(a: number, b: number): Promise<number>;
  postMessage(name: string, payload: any): Promise<any>;
};

const { NativescriptRuntime } = NativeModules;

export default NativescriptRuntime as NativescriptRuntimeType;
