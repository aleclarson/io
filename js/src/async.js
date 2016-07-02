var Promise, async, define, fs, globby, qfs;

Promise = require("Promise");

define = require("define");

globby = require("globby");

qfs = require("q-io/fs");

fs = require("fs");

async = {
  exists: Promise.wrap(function(path) {
    return qfs.exists(path);
  }),
  isFile: Promise.wrap(function(path) {
    return qfs.isFile(path);
  }),
  isDir: Promise.wrap(function(path) {
    return qfs.isDirectory(path);
  }),
  match: function(globs, options) {
    return globby(globs, options);
  },
  readDir: Promise.wrap(function(path) {
    return qfs.list(path);
  }),
  read: Promise.wrap(function(path) {
    return qfs.read(path);
  }),
  stats: Promise.ify(fs.stat),
  makeDir: Promise.wrap(function(path) {
    return qfs.makeTree(path);
  }),
  write: Promise.wrap(function(path, contents) {
    return qfs.write(path, contents);
  }),
  append: Promise.wrap(function(path, contents) {
    return qfs.append(path, contents);
  }),
  copy: Promise.wrap(function(path, dest) {
    return qfs.copyTree(path, dest);
  }),
  move: Promise.wrap(function(path, dest) {
    return qfs.move(path, dest);
  }),
  remove: Promise.wrap(function(path) {
    return qfs.removeTree(path);
  })
};

define(exports, async);

//# sourceMappingURL=../../map/src/async.map
