var defaultEncoding, define, dirname, fs, globby, iconv, join, mkdirp, ref, relative, resolve, rimraf, sync;

ref = require("path"), resolve = ref.resolve, dirname = ref.dirname, relative = ref.relative, join = ref.join;

mkdirp = require("mkdirp");

rimraf = require("rimraf");

globby = require("globby");

define = require("define");

iconv = require("iconv-lite");

fs = require("fs");

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
    contents = fs.readFileSync(String(path));
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
    sync.makeDir(dirname(path));
    if (!Buffer.isBuffer(contents)) {
      contents = iconv.encode(contents, options.encoding != null ? options.encoding : options.encoding = defaultEncoding);
    }
    fs.writeFileSync(path, contents, options);
    return true;
  },
  append: function(path, contents) {
    if (!sync.exists(path)) {
      return false;
    }
    if (!Buffer.isBuffer(contents)) {
      contents = iconv.encode(contents, options.encoding != null ? options.encoding : options.encoding = defaultEncoding);
    }
    fs.appendFileSync(path, contents, options);
    return true;
  },
  exists: function(path) {
    return fs.existsSync(path);
  },
  copy: function(path, dest, options) {
    var child, childDest, contents, i, len, ref1;
    if (options == null) {
      options = {};
    }
    path = resolve(path);
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
      dest = resolve(dest);
      ref1 = sync.match(path + "/**");
      for (i = 0, len = ref1.length; i < len; i++) {
        child = ref1[i];
        if (sync.isFile(child)) {
          childDest = join(dest, relative(path, child));
          sync.copy(child, childDest, options);
        }
      }
    }
  },
  move: function(path, dest) {
    return fs.renameSync(path, dest);
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
    return fs.readdirSync(path);
  },
  isDir: function(path) {
    return sync.exists(path) && sync.stats(path).isDirectory();
  },
  isFile: function(path) {
    return sync.exists(path) && sync.stats(path).isFile();
  },
  stats: function(path) {
    return fs.statSync(path);
  }
});

//# sourceMappingURL=../../map/src/sync.map
