const browserslist = require('browserslist');
const root = process.cwd();

/**
 * An extension of the react-native-builder-bob preset, simply adding '@babel/plugin-transform-classes'.
 * @param {any} babel
 * @param {Object} options
 * @param {"module"|"commonjs"} options.modules
 * @see https://github.com/callstack/react-native-builder-bob/blob/bbe6b1cee27e8d9df88dbc5523a13523789ed40e/packages/react-native-builder-bob/src/utils/compile.ts#L61-L93
 */
module.exports = function (options) {
  return {
    presets: [
      [
        '@babel/preset-env',
        {
          // @ts-ignore
          targets: browserslist.findConfig(root) ?? {
            browsers: [
              '>1%',
              'last 2 chrome versions',
              'last 2 edge versions',
              'last 2 firefox versions',
              'last 2 safari versions',
              'not dead',
              'not ie <= 11',
              'not op_mini all',
              'not android <= 4.4',
              'not samsung <= 4',
            ],
            node: '10',
          },
          useBuiltIns: false,
          modules: options.modules,
        },
      ],
      '@babel/preset-react',
      '@babel/preset-typescript',
      '@babel/preset-flow',
    ],
    plugins: [
      '@babel/plugin-proposal-class-properties',
      // Added simply because we don't have a babel transform for @NativeClass yet.
      '@babel/plugin-transform-classes',
    ],
  };
};
