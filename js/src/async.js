var Promise, define, globby, qfs;

Promise = require("Promise");

define = require("define");

globby = require("globby");

qfs = require("q-io/fs");

define(exports, {
  match: function(globs) {
    return globby(globs);
  },
  read: Promise.wrap(function(path) {
    return qfs.read(path);
  }),
  write: Promise.wrap(function(path, contents) {
    return qfs.write(path, contents);
  }),
  append: Promise.wrap(function(path, contents) {
    return qfs.append(path, contents);
  }),
  exists: Promise.wrap(function(path) {
    return qfs.exists(path);
  }),
  copy: Promise.wrap(function(path, dest) {
    return qfs.copyTree(path, dest);
  }),
  move: Promise.wrap(function(path, dest) {
    return qfs.move(path, dest);
  }),
  remove: Promise.wrap(function(path) {
    return qfs.removeTree(path);
  }),
  makeDir: Promise.wrap(function(path) {
    return qfs.makeTree(path);
  }),
  readDir: Promise.wrap(function(path) {
    return qfs.list(path);
  }),
  isDir: Promise.wrap(function(path) {
    return qfs.isDirectory(path);
  }),
  isFile: Promise.wrap(function(path) {
    return qfs.isFile(path);
  }),
  stats: Promise.wrap(function(path) {
    return qfs.stat(path);
  })
});

//# sourceMappingURL=../../map/src/async.map
