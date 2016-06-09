var FS, Path, defaultEncoding, define, globby, iconv, mkdirp, rimraf, sync;

mkdirp = require("mkdirp");

rimraf = require("rimraf");

globby = require("globby");

define = require("define");

iconv = require("iconv-lite");

Path = require("path");

FS = require("fs");

defaultEncoding = "utf8";

define(sync = exports, {
  match: function(globs) {
    return globby.sync(globs);
  },
  read: function(path, options) {
    var contents;
    if (options == null) {
      options = {};
    }
    contents = FS.readFileSync(String(path));
    if (options.encoding !== null) {
      contents = iconv.decode(contents, options.encoding || defaultEncoding);
      if (contents.charCodeAt(0) === 0xFEFF) {
        contents = contents.slice(1);
      }
    }
    return contents;
  },
  write: function(path, contents, options) {
    if (options == null) {
      options = {};
    }
    sync.makeDir(Path.dirname(path));
    if (!Buffer.isBuffer(contents)) {
      contents = iconv.encode(contents, options.encoding != null ? options.encoding : options.encoding = defaultEncoding);
    }
    FS.writeFileSync(path, contents, options);
    return true;
  },
  append: function(path, contents) {
    if (!sync.exists(path)) {
      return false;
    }
    if (!Buffer.isBuffer(contents)) {
      contents = iconv.encode(contents, options.encoding != null ? options.encoding : options.encoding = defaultEncoding);
    }
    FS.appendFileSync(path, contents, options);
    return true;
  },
  exists: function(path) {
    return FS.existsSync(path);
  },
  copy: function(path, dest, options) {
    var child, childDest, contents, i, len, ref;
    if (options == null) {
      options = {};
    }
    path = Path.resolve(path);
    if (sync.isFile(path)) {
      contents = sync.read(path);
      if (options.force || !sync.exists(dest)) {
        if (options.testRun) {
          console.log("Copying '" + path + "' to '" + dest + "'");
        } else {
          return sync.write(dest, contents, options);
        }
      }
      return false;
    } else if (sync.isDir(path)) {
      dest = Path.resolve(dest);
      ref = sync.match(path + "/**");
      for (i = 0, len = ref.length; i < len; i++) {
        child = ref[i];
        if (sync.isFile(child)) {
          childDest = Path.join(dest, Path.relative(path, child));
          sync.copy(child, childDest, options);
        }
      }
    }
  },
  move: function(path, dest) {
    return FS.renameSync(path, dest);
  },
  remove: function(path) {
    path = String(path);
    if (!sync.exists(path)) {
      return false;
    }
    rimraf.sync(path);
    return true;
  },
  makeDir: function(path) {
    return mkdirp.sync(path);
  },
  readDir: function(path) {
    return FS.readdirSync(path);
  },
  isDir: function(path) {
    return sync.exists(path) && sync.stats(path).isDirectory();
  },
  isFile: function(path) {
    return sync.exists(path) && sync.stats(path).isFile();
  },
  stats: function(path) {
    return FS.statSync(path);
  }
});

//# sourceMappingURL=../../map/src/sync.map
