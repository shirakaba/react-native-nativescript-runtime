/* eslint-disable eslint-comments/no-unlimited-disable */
/* eslint-disable */
const util = require('util');
const cp = require('child_process');
const exec = util.promisify(cp.exec);
const fs = require('fs');
const stat = util.promisify(fs.stat);
const path = require('path');

const loggingLabel = `[react-native-nativescript-runtime/extractFrameworks.js]`;

const pathToIosResources = path.resolve(path.dirname(__dirname), 'ios');
const zipFileName = 'Frameworks.zip';
const pathToFrameworksZip = path.resolve(pathToIosResources, zipFileName);
const pathsToFrameworksZipContents = [
  path.resolve(pathToIosResources, 'TNSWidgets.xcframework'),
  path.resolve(pathToIosResources, 'NativeScript.xcframework'),
];

/**
 * Checks whether Frameworks.zip (which contains two xcframeworks) has been unzipped yet.
 * TODO: Check whether Android similarly needs any resources unzipped.
 * @returns {Promise<boolean>} true if it has been unzipped, or false if not.
 */
async function frameworkIsUnzipped(pathsToFrameworksZipContents) {
  const results = await Promise.all(
    pathsToFrameworksZipContents.map(async (p) => {
      try {
        await stat(p);
        return true;
      } catch (error) {
        if (error.code === 'ENOENT') {
          return false;
        }
        throw new Error(
          `Failed to check whether path ${p} exists: ${error.message}`
        );
      }
    })
  );

  return !results.some((result) => !result);
}

/**
 * Unzips Frameworks.zip such that its contents end up beside it.
 * TODO: Use cross-platform unzipping library, as this plugin gives you both Android and iOS so we can't expect to be on a Mac.
 * @see https://github.com/ZJONSSON/node-unzipper#readme
 * @returns {Promise<void>}
 */
async function unzipFramework(pathToFrameworksZip, pathToIosResources) {
  try {
    await exec(`unzip "${pathToFrameworksZip}" -d "${pathToIosResources}"`);
  } catch (error) {
    throw new Error(
      `${loggingLabel} Error unzipping ${zipFileName}: ${error.message}`
    );
  }
}

async function main() {
  const isUnzipped = await frameworkIsUnzipped();
  if (isUnzipped) {
    console.log(
      `${loggingLabel} NativeScript runtime already unzipped, so skipping.`,
      error
    );
    return process.exit(0);
  }
  await unzipFramework();
}

main().catch((error) => {
  console.error(
    `${loggingLabel} Unable to complete postinstall script.`,
    error
  );
  return process.exit(1);
});
