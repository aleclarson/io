var Promise, Reader, Writer, appendFile, assertType, copyFile, copyTree, emptyFunction, exists, fs, globby, has, isDir, isFile, makeTree, match, moveTree, openFile, path, promised, readFile, readStats, readTree, removeTree, writeFile;

emptyFunction = require("emptyFunction");

assertType = require("assertType");

Promise = require("Promise");

globby = require("globby");

path = require("path");

has = require("has");

fs = require("fs");

Reader = require("./reader");

Writer = require("./writer");

require("graceful-fs").gracefulify(fs);

promised = {
  "stat": "stat",
  "lstat": "lstat",
  "rename": "rename",
  "symlink": "symlink",
  "unlink": "unlink",
  "readdir": "readdir",
  "mkdir": "mkdir"
};

Object.keys(promised).forEach(function(key) {
  return promised[key] = Promise.ify(fs[key]);
});

exists = function(filePath) {
  var onFulfilled, onRejected;
  onFulfilled = emptyFunction.thatReturnsTrue;
  onRejected = emptyFunction.thatReturnsFalse;
  return promised.stat(filePath).then(onFulfilled, onRejected);
};

isFile = function(filePath) {
  var onFulfilled, onRejected;
  onFulfilled = function(stats) {
    return stats.isFile();
  };
  onRejected = emptyFunction.thatReturnsFalse;
  return promised.stat(filePath).then(onFulfilled, onRejected);
};

isDir = function(filePath) {
  var onFulfilled, onRejected;
  onFulfilled = function(stats) {
    return stats.isDirectory();
  };
  onRejected = emptyFunction.thatReturnsFalse;
  return promised.stat(filePath).then(onFulfilled, onRejected);
};

readStats = function(filePath) {
  return promised.stat(filePath);
};

readFile = function(filePath, options) {
  return openFile(filePath, options).read();
};

openFile = function(filePath, options) {
  var config, encoding, stream;
  if (options == null) {
    options = {};
  }
  assertType(filePath, String);
  assertType(options, Object);
  config = {};
  if (has(options, "start")) {
    config.start = options.start;
    config.end = options.end - 1;
  }
  if (has(options, "bufferSize")) {
    config.bufferSize = options.bufferSize;
  }
  encoding = null;
  if (options.encoding !== null) {
    encoding = options.encoding || "utf-8";
  }
  if (options.writable) {
    if (has(options, "mode")) {
      config.mode = options.mode;
    }
    if (options.append) {
      config.flags = "a";
    }
    stream = fs.createWriteStream(filePath, config);
    return Writer(stream, encoding);
  }
  stream = fs.createReadStream(filePath, config);
  return Reader(stream, encoding);
};

readTree = function(filePath) {
  assertType(filePath, String);
  return promised.readdir(filePath);
};

match = function(globs, options) {
  assertType(globs, [String, Array]);
  assertType(options, Object.Maybe);
  return globby(globs, options);
};

writeFile = function(filePath, newValue, options) {
  if (options == null) {
    options = {};
  }
  assertType(filePath, String);
  assertType(newValue, [String, Buffer]);
  assertType(options, Object);
  if (newValue instanceof Buffer) {
    options.encoding = null;
  }
  return makeTree(path.dirname(filePath)).then(function() {
    var writer;
    options.writable = true;
    writer = openFile(filePath, options);
    return writer.write(newValue).then(function() {
      return writer.close();
    });
  });
};

appendFile = function(filePath, value, options) {
  if (options == null) {
    options = {};
  }
  options.append = true;
  return writeFile(filePath, value, options);
};

copyFile = function(fromPath, toPath) {
  assertType(fromPath, String);
  assertType(toPath, String);
  return promised.stat(fromPath).then(function(stats) {
    var reader, writer;
    reader = openFile(fromPath);
    writer = openFile(toPath, {
      mode: stats.mode
    });
    return reader.forEach(writer.write).then(function() {
      return writer.close();
    });
  });
};

makeTree = function(filePath, mode) {
  var dirPath;
  if (mode == null) {
    mode = "755";
  }
  assertType(filePath, String);
  assertType(mode, [String, Number]);
  if (typeof mode === "string") {
    mode = parseInt(mode, 8);
  }
  dirPath = path.dirname(filePath);
  return exists(dirPath).then(function(dirExists) {
    return dirExists || makeTree(dirPath, mode);
  }).then(function() {
    return promised.mkdir(filePath, mode).fail(function(error) {
      if (error.code === "EEXIST") {
        return;
      }
      throw error;
    });
  });
};

copyTree = function(fromPath, toPath) {
  assertType(fromPath, String);
  assertType(toPath, String);
  return promised.stat(fromPath).then(function(stats) {
    if (stats.isSymbolicLink()) {
      return promised.symlink(toPath, fromPath, "file");
    }
    if (stats.isFile()) {
      return copyFile(fromPath, toPath);
    }
    return exists(toPath).then(function(exists) {
      return exists || makeTree(toPath, stats.node.mode);
    }).then(function() {
      return promised.readdir(fromPath);
    }).then(function(children) {
      return Promise.map(children, function(child) {
        var fromChild, toChild;
        fromChild = path.join(fromPath, child);
        toChild = path.join(toPath, child);
        return copyTree(fromChild, toChild);
      });
    });
  });
};

moveTree = function(fromPath, toPath) {
  assertType(fromPath, String);
  assertType(toPath, String);
  return rename(fromPath, toPath).fail(function(error) {
    if (error.code === "EXDEV") {
      return copyTree(fromPath, toPath).then(function() {
        return removeTree(fromPath);
      });
    }
    throw error;
  });
};

removeTree = function(filePath) {
  assertType(filePath, String);
  return promised.lstat(filePath).then(function(stats) {
    if (!stats.isDirectory()) {
      return promised.unlink(filePath);
    }
    return promised.readdir(filePath).then(function(children) {
      return Promise.map(children, function(child) {
        return removeTree(path.join(filePath, child));
      });
    });
  });
};

module.exports = {
  exists: exists,
  isFile: isFile,
  isDir: isDir,
  stats: readStats,
  read: readFile,
  open: openFile,
  write: writeFile,
  append: appendFile,
  match: match,
  readDir: readTree,
  makeDir: makeTree,
  copy: copyTree,
  move: moveTree,
  remove: removeTree
};

//# sourceMappingURL=map/async.map
