var UTF8, assert, assertType, define, fs, globby, iconv, mkdirp, path, rimraf, sync;

assertType = require("assertType");

rimraf = require("rimraf");

mkdirp = require("mkdirp");

globby = require("globby");

define = require("define");

assert = require("assert");

iconv = require("iconv-lite");

path = require("path");

fs = require("fs");

UTF8 = "utf8";

sync = {
  exists: function(filePath) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    return fs.existsSync(filePath);
  },
  isFile: function(filePath) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    return sync.exists(filePath) && sync.stats(filePath).isFile();
  },
  isDir: function(filePath) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    return sync.exists(filePath) && sync.stats(filePath).isDirectory();
  },
  match: function(globs, options) {
    assertType(globs, [String, Array]);
    return globby.sync(globs, options);
  },
  readDir: function(filePath) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    assert(sync.isDir(filePath), "'filePath' must be an existing directory!");
    return fs.readdirSync(filePath);
  },
  read: function(filePath, options) {
    var contents;
    if (options == null) {
      options = {};
    }
    assertType(filePath, String);
    assertType(options, Object);
    assert(sync.isFile(filePath), "'filePath' must be an existing file!");
    contents = fs.readFileSync(filePath);
    if (options.encoding !== null) {
      contents = iconv.decode(contents, options.encoding || UTF8);
      if (contents.charCodeAt(0) === 0xFEFF) {
        contents = contents.slice(1);
      }
    }
    return contents;
  },
  stats: function(filePath) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    return fs.statSync(filePath);
  },
  makeDir: function(filePath) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    assert(!sync.isFile(filePath), "'filePath' must be a directory or not exist!");
    return mkdirp.sync(filePath);
  },
  write: function(filePath, contents, options) {
    if (options == null) {
      options = {};
    }
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    assert(!sync.isDir(filePath), "'filePath' cannot be a directory!");
    sync.makeDir(path.dirname(filePath));
    assertType(contents, [String, Buffer]);
    if (!Buffer.isBuffer(contents)) {
      if (options.encoding == null) {
        options.encoding = UTF8;
      }
    }
    contents = iconv.encode(contents, options.encoding);
    fs.writeFileSync(filePath, contents, options);
  },
  append: function(filePath, contents) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    assert(!sync.isDir(filePath), "'filePath' cannot be a directory!");
    if (!sync.exists(filePath)) {
      return sync.write(filePath, contents);
    }
    assertType(contents, [String, Buffer]);
    if (!Buffer.isBuffer(contents)) {
      if (options.encoding == null) {
        options.encoding = UTF8;
      }
    }
    contents = iconv.encode(contents, options.encoding);
    fs.appendFileSync(filePath, contents, options);
  },
  copy: function(filePath, destPath, options) {
    if (options == null) {
      options = {};
    }
    assertType(filePath, String);
    assertType(destPath, String);
    assertType(options, Object);
    filePath = path.resolve(filePath);
    destPath = path.resolve(destPath);
    assert(sync.exists(filePath), "'filePath' must exist!");
    if (sync.isDir(filePath)) {
      if (options.testRun) {
        if (!sync.exists(destPath)) {
          console.log("Creating '" + destPath + "'");
        }
      } else {
        sync.makeDir(destPath);
      }
      return sync.readDir(filePath).forEach(function(childName) {
        var childDest, childPath;
        childPath = path.join(filePath, childName);
        if (sync.isDir(childPath) && !options.recursive) {
          return;
        }
        childDest = path.join(destPath, childName);
        return sync.copy(childPath, childDest, options);
      });
    }
    assert(options.force || !sync.exists(destPath), "'destPath' must not exist!");
    if (options.testRun) {
      console.log("Copying '" + filePath + "' to '" + destPath + "'");
      return;
    }
    sync.write(destPath, sync.read(filePath));
  },
  move: function(filePath, destPath) {
    assertType(filePath, String);
    assertType(destPath, String);
    filePath = path.resolve(filePath);
    destPath = path.resolve(destPath);
    assert(sync.exists(filePath), "'filePath' must exist!");
    assert(!sync.exists(destPath), "'destPath' must not exist!");
    sync.makeDir(path.dirname(destPath));
    fs.renameSync(filePath, destPath);
  },
  remove: function(filePath) {
    assertType(filePath, String);
    filePath = path.resolve(filePath);
    if (!sync.exists(filePath)) {
      return false;
    }
    rimraf.sync(filePath);
    return true;
  }
};

define(exports, sync);

//# sourceMappingURL=../../map/src/sync.map
