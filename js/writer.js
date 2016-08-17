var Null, Promise, StringOrNull, Type, Typle, fs, type;

Promise = require("Promise");

Typle = require("Typle");

Type = require("Type");

Null = require("Null");

fs = require("fs");

StringOrNull = Typle([String, Null]);

type = Type("Writer");

type.defineArgs({
  stream: {
    type: fs.WriteStream,
    required: true
  },
  encoding: {
    type: StringOrNull,
    encoding: "utf-8"
  }
});

type.defineFrozenValues(function(stream) {
  return {
    _stream: stream
  };
});

type.defineValues(function() {
  return {
    _drained: Promise.defer()
  };
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
    if (!(this._stream.writeable || this._stream.writable)) {
      throw Error("Can't write to non-writable (possibly closed) stream!");
    }
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
