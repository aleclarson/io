var Null, Promise, StringOrNull, Type, Typle, emptyFunction, fs, type;

emptyFunction = require("emptyFunction");

Promise = require("Promise");

Typle = require("Typle");

Type = require("Type");

Null = require("Null");

fs = require("fs");

StringOrNull = Typle([String, Null]);

type = Type("Reader");

type.defineArgs({
  stream: {
    type: fs.ReadStream,
    required: true
  },
  encoding: {
    type: StringOrNull,
    "default": "utf-8"
  }
});

type.defineFrozenValues(function(stream, encoding) {
  return {
    _stream: stream,
    _encoding: encoding,
    _end: Promise.defer(),
    _chunks: []
  };
});

type.defineValues(function() {
  return {
    _receiver: this._defaultReceiver
  };
});

type.initInstance(function(stream, encoding) {
  if (encoding && stream.setEncoding) {
    stream.setEncoding(encoding);
  }
  stream.on("error", (function(_this) {
    return function(error) {
      return _this._end.reject(error);
    };
  })(this));
  stream.on("end", (function(_this) {
    return function() {
      return _this._end.resolve();
    };
  })(this));
  return stream.on("data", (function(_this) {
    return function(chunk) {
      return _this._receiver(chunk);
    };
  })(this));
});

type.defineMethods({
  read: function() {
    this._receiver = this._defaultReceiver;
    return this._end.promise.then((function(_this) {
      return function() {
        var contents;
        _this._receiver = emptyFunction;
        contents = _this._read();
        _this._chunks.length = 0;
        return contents;
      };
    })(this));
  },
  forEach: function(receiver) {
    this._receiver = receiver;
    if (this._chunks.length) {
      receiver(this._read());
      this._chunks.length = 0;
    }
    return this._end.promise.always((function(_this) {
      return function() {
        _this._receiver = emptyFunction;
      };
    })(this));
  },
  close: function() {
    this._stream.destroy();
  },
  _defaultReceiver: function(chunk) {
    return this._chunks.push(chunk);
  },
  _read: function() {
    if (!this._encoding) {
      return this._join();
    }
    return this._chunks.join("");
  },
  _join: function() {
    var chunk, chunks, count, index, length, offset;
    chunks = this._chunks;
    count = chunks.length;
    length = 0;
    index = -1;
    while (++index < count) {
      length += chunks[index].length;
    }
    chunk = new Buffer(length);
    offset = 0;
    index = -1;
    while (++index < count) {
      chunks[index].copy(chunk, offset, 0);
      offset += chunks[index].length;
    }
    return chunk;
  }
});

module.exports = type.build();

//# sourceMappingURL=map/reader.map
