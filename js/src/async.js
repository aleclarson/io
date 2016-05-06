var define, globby, q, qfs;

define = require("define");

globby = require("globby");

qfs = require("q-io/fs");

q = require("q");

define(exports, {
  match: function(globs) {
    return q.nfcall(globby, globs);
  },
  read: function(path) {
    return qfs.read(path);
  },
  write: function(path, contents) {
    return qfs.write(path, contents);
  },
  append: function(path, contents) {
    return qfs.append(path, contents);
  },
  exists: function(path) {
    return qfs.exists(path);
  },
  copy: function(path, dest) {
    return qfs.copyTree(path, dest);
  },
  move: function(path, dest) {
    return qfs.move(path, dest);
  },
  remove: function(path) {
    return qfs.removeTree(path);
  },
  makeDir: function(path) {
    return qfs.makeTree(path);
  },
  readDir: function(path) {
    return qfs.list(path);
  },
  isDir: function(path) {
    return qfs.isDirectory(path);
  },
  isFile: function(path) {
    return qfs.isFile(path);
  },
  stats: function(path) {
    return qfs.stat(path);
  }
});

//# sourceMappingURL=../../map/src/async.map
