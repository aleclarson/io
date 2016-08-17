var StringOrArray, StringOrBuffer, Typle, UTF8, appendFile, assertType, copyTree, exists, fs, globby, iconv, isDir, isFile, makeTree, match, mkdirp, moveTree, path, readFile, readTree, removeTree, rimraf, stats, writeFile;

assertType = require("assertType");

rimraf = require("rimraf");

mkdirp = require("mkdirp");

globby = require("globby");

Typle = require("Typle");

iconv = require("iconv-lite");

path = require("path");

fs = require("fs");

UTF8 = "utf8";

StringOrArray = Typle([String, Array]);

StringOrBuffer = Typle([String, Buffer]);

exists = function(filePath) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  return fs.existsSync(filePath);
};

isFile = function(filePath) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  return exists(filePath) && stats(filePath).isFile();
};

isDir = function(filePath) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  return exists(filePath) && stats(filePath).isDirectory();
};

stats = function(filePath) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  return fs.statSync(filePath);
};

readFile = function(filePath, options) {
  var contents;
  if (options == null) {
    options = {};
  }
  assertType(filePath, String);
  assertType(options, Object);
  if (!isFile(filePath)) {
    throw Error("'filePath' must be an existing file!");
  }
  contents = fs.readFileSync(filePath);
  if (options.encoding !== null) {
    contents = iconv.decode(contents, options.encoding || UTF8);
    if (contents.charCodeAt(0) === 0xFEFF) {
      contents = contents.slice(1);
    }
  }
  return contents;
};

appendFile = function(filePath, contents) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  if (isDir(filePath)) {
    throw Error("'filePath' cannot be a directory!");
  }
  if (!exists(filePath)) {
    return writeFile(filePath, contents);
  }
  assertType(contents, StringOrBuffer);
  if (!Buffer.isBuffer(contents)) {
    if (options.encoding == null) {
      options.encoding = UTF8;
    }
  }
  contents = iconv.encode(contents, options.encoding);
  fs.appendFileSync(filePath, contents, options);
};

readTree = function(filePath) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  if (!isDir(filePath)) {
    throw Error("'filePath' must be an existing directory!");
  }
  return fs.readdirSync(filePath);
};

match = function(globs, options) {
  assertType(globs, StringOrArray);
  assertType(options, Object.Maybe);
  return globby.sync(globs, options);
};

writeFile = function(filePath, contents, options) {
  if (options == null) {
    options = {};
  }
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  if (isDir(filePath)) {
    throw Error("'filePath' cannot be a directory!");
  }
  makeTree(path.dirname(filePath));
  assertType(contents, StringOrBuffer);
  if (!Buffer.isBuffer(contents)) {
    if (options.encoding == null) {
      options.encoding = UTF8;
    }
  }
  contents = iconv.encode(contents, options.encoding);
  fs.writeFileSync(filePath, contents, options);
};

makeTree = function(filePath) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  if (isFile(filePath)) {
    throw Error("'filePath' must be a directory or not exist!");
  }
  return mkdirp.sync(filePath);
};

copyTree = function(fromPath, toPath, options) {
  if (options == null) {
    options = {};
  }
  assertType(fromPath, String);
  assertType(toPath, String);
  assertType(options, Object);
  fromPath = path.resolve(fromPath);
  toPath = path.resolve(toPath);
  if (!exists(fromPath)) {
    throw Error("Expected 'fromPath' to exist: '" + fromPath + "'");
  }
  if (isDir(fromPath)) {
    if (options.testRun) {
      if (!exists(toPath)) {
        console.log("Creating '" + toPath + "'");
      }
    } else {
      makeTree(toPath);
    }
    return readTree(fromPath).forEach(function(child) {
      var fromChild, toChild;
      fromChild = path.join(fromPath, child);
      if (isDir(fromChild) && !options.recursive) {
        return;
      }
      toChild = path.join(toPath, child);
      return copyTree(fromChild, toChild, options);
    });
  }
  if (!(options.force || !exists(toPath))) {
    throw Error("Expected 'toPath' to not exist: '" + toPath + "'");
  }
  if (options.testRun) {
    console.log("Copying '" + fromPath + "' to '" + toPath + "'");
    return;
  }
  writeFile(toPath, readFile(fromPath));
};

moveTree = function(fromPath, toPath) {
  assertType(fromPath, String);
  assertType(toPath, String);
  fromPath = path.resolve(fromPath);
  toPath = path.resolve(toPath);
  if (!exists(fromPath)) {
    throw Error("Expected 'fromPath' to exist: '" + fromPath + "'");
  }
  if (exists(toPath)) {
    throw Error("Expected 'toPath' to not exist: '" + toPath + "'");
  }
  makeTree(path.dirname(toPath));
  fs.renameSync(fromPath, toPath);
};

removeTree = function(filePath) {
  assertType(filePath, String);
  filePath = path.resolve(filePath);
  if (!exists(filePath)) {
    return false;
  }
  rimraf.sync(filePath);
  return true;
};

module.exports = {
  exists: exists,
  isFile: isFile,
  isDir: isDir,
  stats: stats,
  read: readFile,
  write: writeFile,
  append: appendFile,
  match: match,
  readDir: readTree,
  makeDir: makeTree,
  copy: copyTree,
  move: moveTree,
  remove: removeTree
};

//# sourceMappingURL=map/sync.map
