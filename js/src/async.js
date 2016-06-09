var Promise, define, globby, qfs;

Promise = require("Promise");

define = require("define");

globby = require("globby");

qfs = require("q-io/fs");

define(exports, {
  match: function(globs) {
    return globby.async(globs);
  },
  read: function(path) {
    return Promise(qfs.read(path));
  },
  write: function(path, contents) {
    return Promise(qfs.write(path, contents));
  },
  append: function(path, contents) {
    return Promise(qfs.append(path, contents));
  },
  exists: function(path) {
    return Promise(qfs.exists(path));
  },
  copy: function(path, dest) {
    return Promise(qfs.copyTree(path, dest));
  },
  move: function(path, dest) {
    return Promise(qfs.move(path, dest));
  },
  remove: function(path) {
    return Promise(qfs.removeTree(path));
  },
  makeDir: function(path) {
    return Promise(qfs.makeTree(path));
  },
  readDir: function(path) {
    return Promise(qfs.list(path));
  },
  isDir: function(path) {
    return Promise(qfs.isDirectory(path));
  },
  isFile: function(path) {
    return Promise(qfs.isFile(path));
  },
  stats: function(path) {
    return Promise(qfs.stat(path));
  }
});

//# sourceMappingURL=../../map/src/async.map
