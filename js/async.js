var Promise, Reader, Writer, appendFile, assert, assertType, copyFile, copyTree, emptyFunction, exists, fs, globby, isDir, isFile, lstats, makeTree, match, mkdir, moveTree, openFile, path, readFile, readTree, readdir, removeTree, rename, stats, symlink, unlink, writeFile,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

emptyFunction = require("emptyFunction");

assertType = require("assertType");

Promise = require("Promise");

globby = require("globby");

assert = require("assert");

path = require("path");

fs = require("fs");

Reader = require("./reader");

Writer = require("./writer");

require("graceful-fs").gracefulify(fs);

stats = Promise.ify(fs.stat);

lstats = Promise.ify(fs.lstat);

rename = Promise.ify(fs.rename);

symlink = Promise.ify(fs.symlink);

unlink = Promise.ify(fs.unlink);

readdir = Promise.ify(fs.readdir);

mkdir = Promise.ify(fs.mkdir);

exists = function(filePath) {
  var onFulfilled, onRejected;
  onFulfilled = emptyFunction.thatReturnsTrue;
  onRejected = emptyFunction.thatReturnsFalse;
  return stats(filePath).then(onFulfilled, onRejected);
};

isFile = function(filePath) {
  var onFulfilled, onRejected;
  onFulfilled = function(stats) {
    return stats.isFile();
  };
  onRejected = emptyFunction.thatReturnsFalse;
  return stats(filePath).then(onFulfilled, onRejected);
};

isDir = function(filePath) {
  var onFulfilled, onRejected;
  onFulfilled = function(stats) {
    return stats.isDirectory();
  };
  onRejected = emptyFunction.thatReturnsFalse;
  return stats(filePath).then(onFulfilled, onRejected);
};

readFile = function(filePath, options) {
  if (options == null) {
    options = {};
  }
  return openFile(filePath, options).then(function(stream) {
    return stream.read();
  });
};

openFile = function(filePath, options) {
  var stream, streamConfig;
  if (options == null) {
    options = {};
  }
  assertType(filePath, String);
  assertType(options, Object);
  if (options.flags == null) {
    options.flags = "r";
  }
  streamConfig = {
    flags: options.flags.replace(/b/g, "") || "r"
  };
  if (indexOf.call(options, "bufferSize") >= 0) {
    streamConfig.bufferSize = options.bufferSize;
  }
  if (indexOf.call(options, "mode") >= 0) {
    streamConfig.mode = options.mode;
  }
  if (indexOf.call(options, "begin") >= 0) {
    streamConfig.start = options.begin;
    streamConfig.end = options.end - 1;
  }
  if (options.flags.indexOf("b") >= 0) {
    assert(!options.charset, "Cannot open a binary file with a charset: " + options.charset);
  } else {
    if (options.charset == null) {
      options.charset = "utf-8";
    }
  }
  if (options.flags.indexOf("w") >= 0 || options.flags.indexOf("a") >= 0) {
    stream = fs.createWriteStream(filePath, streamConfig);
    return Writer(stream, options.charset);
  }
  stream = fs.createReadStream(filePath, streamConfig);
  return Reader(stream, options.charset);
};

readTree = function(filePath) {
  assertType(filePath, String);
  return readdir(filePath);
};

match = function(globs, options) {
  assertType(globs, [String, Array]);
  assertType(options, Object.Maybe);
  return globby(globs, options);
};

writeFile = function(filePath, value, options) {
  if (options == null) {
    options = {};
  }
  assertType(filePath, String);
  assertType(value, [String, Buffer]);
  assertType(options, Object);
  if (options.flags == null) {
    options.flags = "w";
  }
  if (options.flags.indexOf("b") >= 0) {
    if (!(value instanceof Buffer)) {
      value = new Buffer(value);
    }
  } else if (value instanceof Buffer) {
    options.flags += "b";
  }
  return openFile(filePath, options).then(function(stream) {
    return stream.write(value).then(stream.close);
  });
};

appendFile = function(filePath, value, options) {
  if (options == null) {
    options = {};
  }
  assertType(filePath, String);
  assertType(value, [String, Buffer]);
  assertType(options, Object);
  if (options.flags == null) {
    options.flags = "a";
  }
  if (options.flags.indexOf("b") >= 0) {
    if (!(value instanceof Buffer)) {
      value = new Buffer(value);
    }
  } else if (value instanceof Buffer) {
    options.flags += "b";
  }
  return openFile(filePath, options).then(function(stream) {
    return stream.write(value).then(stream.close);
  });
};

copyFile = function(fromPath, toPath) {
  assertType(fromPath, String);
  assertType(toPath, String);
  return stats(fromPath).then(function(stats) {
    var reader, writer;
    reader = openFile(fromPath, {
      flags: "rb"
    });
    writer = openFile(toPath, {
      flags: "wb",
      mode: stats.node.mode
    });
    return Promise.all([reader, writer]).then([reader, writer])(function() {
      return reader.forEach(writer.write).then(function() {
        return Promise.all([reader.close(), write.close()]);
      });
    });
  });
};

makeTree = function(filePath, mode) {
  if (mode == null) {
    mode = "755";
  }
  assertType(filePath, String);
  assertType(mode, [String, Number]);
  if (typeof mode === "string") {
    mode = parseInt(mode, 8);
  }
  return mkdir(filePath, mode);
};

copyTree = function(fromPath, toPath) {
  assertType(fromPath, String);
  assertType(toPath, String);
  return stats(fromPath).then(function(stats) {
    if (stats.isFile()) {
      return copyFile(fromPath, toPath);
    }
    if (stats.isDirectory()) {
      return exists(toPath).then(function(exists) {
        return exists || makeTree(toPath, stats.node.mode);
      }).then(function() {
        return readdir(fromPath);
      }).then(function(children) {
        return Promise.map(children, function(child) {
          var fromChild, toChild;
          if (path.isAbsolute(child)) {
            child = path.relative(fromPath);
          }
          fromChild = path.join(fromPath, child);
          toChild = path.join(toPath, child);
          return copyTree(fromChild, toChild);
        });
      });
    }
    if (stats.isSymbolicLink()) {
      return symlink(toPath, fromPath, "file");
    }
  });
};

moveTree = function(fromPath, toPath) {
  assertType(fromPath, String);
  assertType(toPath, String);
  return rename(fromPath, toPath).fail(function(error) {
    if (error.code !== "EXDEV") {
      return copyTree(fromPath, toPath).then(function() {
        return removeTree(fromPath);
      });
    }
    throw error;
  });
};

removeTree = function(filePath) {
  assertType(filePath, String);
  return lstat(filePath).then(function(stats) {
    if (stats.isSymbolicLink() || !stats.isDirectory()) {
      return unlink(filePath);
    }
    return readdir(filePath).then(function(children) {
      return Promise.map(children, function(child) {
        if (!path.isAbsolute(child)) {
          child = path.join(filePath, child);
        }
        return removeTree(child);
      });
    });
  });
};

module.exports = {
  exists: exists,
  isFile: isFile,
  isDir: isDir,
  stats: stats,
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
