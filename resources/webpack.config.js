const { join, relative, resolve, sep } = require('path');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const hashSalt = Date.now().toString();

// FIXME: Restructure react-native-nativescript-runtime to allow importing other than at the root (as the root pulls in react-native and evidently isn't tree-shaken out)
module.exports = (env, argv) => {
  env = env || {};
  const {
    "project-dir": _projectDir,
    "nativescript-root": _nativescriptRoot,
    production,
    uglify
  } = env;

  const projectDir = resolve(_projectDir);
  const nativescriptRoot = resolve(_nativescriptRoot);

  const srcContext = resolve(join(nativescriptRoot, 'src'));

  const tsConfigPath = resolve(join(nativescriptRoot, 'tsconfig.json'));
  const coreModulesPackageName = '@nativescript/core';
  const alias = env.alias || {};
  const dist = resolve(join(nativescriptRoot, "build"));
  const itemsToClean = [`${dist}/*`];

  const config = {
    mode: production ? 'production' : 'development',
    context: srcContext,
    entry: {
      index: './index.ts',
    },
    output: {
      pathinfo: false,
      path: dist,
      libraryTarget: 'commonjs2',
      filename: 'nativescript-bundle.js',
      globalObject: 'global',
      hashSalt,
    },
    resolve: {
      extensions: ['.ts', '.js'],
      // Resolve {N} system modules from @nativescript/core
      modules: [
        resolve(projectDir, `node_modules/${coreModulesPackageName}`),
        resolve(projectDir, 'node_modules'),
        `node_modules/${coreModulesPackageName}`,
        'node_modules',
      ],
      alias,
      // resolve symlinks to symlinked modules
      symlinks: true,
    },
    resolveLoader: {
      // don't resolve symlinks to symlinked loaders
      symlinks: false,
    },
    node: {
      // Disable node shims that conflict with NativeScript
      http: false,
      timers: false,
      setImmediate: false,
      fs: 'empty',
      __dirname: false,
    },
    devtool: 'none',
    optimization: {
      noEmitOnErrors: true,
      minimize: !!uglify,
      minimizer: [
        new TerserPlugin({
          parallel: true,
          cache: false,
          sourceMap: false,
          terserOptions: {
            output: {
              comments: false,
              semicolons: false,
            },
            compress: {
              // The Android SBG has problems parsing the output
              // when these options are enabled
              collapse_vars: false,
              sequences: false,
              // For v8 Compatibility
              keep_infinity: true, // for V8
              reduce_funcs: false, // for V8
              // custom
              drop_console: !!production,
              drop_debugger: true,
              global_defs: {
                __UGLIFIED__: true,
              },
            },
            // Required for Element Level CSS, Observable Events, & Android Frame
            keep_classnames: true,
          },
        }),
      ],
    },
    module: {
      rules: [
        {
          test: /\.ts$/,
          use: {
            loader: 'ts-loader',
            options: {
              configFile: tsConfigPath,
              transpileOnly: true,
              allowTsInNodeModules: true,
              compilerOptions: {
                sourceMap: false,
                declaration: false,
              },
              getCustomTransformers: program => ({
                before: [
                  require('@nativescript/webpack/transformers/ns-transform-native-classes')
                    .default,
                ],
              }),
            },
          },
        },
      ],
    },
    plugins: [
      // Remove all files from the out dir.
      new CleanWebpackPlugin({
        cleanOnceBeforeBuildPatterns: itemsToClean,
        dry: false,
        dangerouslyAllowCleanPatternsOutsideProject: true,
        verbose: false,
      }),
    ],
  };

  return config;
};
