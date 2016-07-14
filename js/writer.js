var Null, Promise, Type, assert, fs, getArgProp, type;

getArgProp = require("getArgProp");

Promise = require("Promise");

assert = require("assert");

Null = require("Null");

Type = require("Type");

fs = require("fs");

type = Type("Writer");

type.argumentTypes = {
  stream: fs.WriteStream,
  encoding: [String, Null]
};

type.argumentDefaults = {
  encoding: "utf-8"
};

type.defineFrozenValues({
  _stream: getArgProp(0)
});

type.defineValues({
  _drained: function() {
    return Promise.defer();
  }
});

type.initInstance(function(stream, encoding) {
  if (encoding && stream.setEncoding) {
    stream.setEncoding(encoding);
  }
  stream.on("error", (function(_this) {
    return function(error) {
      _this._drained.reject(error);
      return _this._drained = Promise.defer();
    };
  })(this));
  return stream.on("drain", (function(_this) {
    return function() {
      _this._drained.resolve();
      return _this._drained = Promise.defer();
    };
  })(this));
});

type.defineMethods({
  write: function(newValue) {
    assert(this._stream.writeable || this._stream.writable, "Can't write to non-writable (possibly closed) stream!");
    if (this._stream.write(newValue)) {
      return Promise();
    }
    return this._drained.promise;
  },
  flush: function() {
    return this._drained.promise;
  },
  close: function() {
    var finished;
    finished = Promise.defer();
    this._stream.on("finish", finished.resolve);
    this._stream.on("error", finished.reject);
    this._stream.end();
    this._drained.resolve();
    return finished.promise;
  },
  destroy: function() {
    this._stream.destroy();
    this._drained.resolve();
  }
});

module.exports = type.build();

//# sourceMappingURL=map/writer.map
