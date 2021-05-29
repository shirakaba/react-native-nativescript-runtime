module.exports = {
  presets: ['module:metro-react-native-babel-preset'],
  plugins: [
    // Added simply because we don't have a babel transform for @NativeClass yet.
    '@babel/plugin-transform-classes',
  ],
};
