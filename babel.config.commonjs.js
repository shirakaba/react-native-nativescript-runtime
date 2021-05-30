const babelConfigBase = require('./babel.config.base');

module.exports = {
  ...babelConfigBase({
    module: 'commonjs',
  }),
};
