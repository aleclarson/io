var NamedFunction, Promise, Writer, supportsFinish, version;

NamedFunction = require("NamedFunction");

Promise = require("Promise");

version = process.versions.node.split(".");

supportsFinish = version[0] >= 0 && version[1] >= 10;

Writer = NamedFunction("Writer", function(_stream, charset) {
  var drained, self;
  self = Object.create(Writer.prototype);
  if (charset && _stream.setEncoding) {
    _stream.setEncoding(charset);
  }
  drained = Promise.defer();
  _stream.on("error", function(reason) {
    drained.reject(reason);
    return drained = Promise.defer();
  });
  _stream.on("drain", function() {
    drained.resolve();
    return drained = Promise.defer();
  });
  self.write = Promise.wrap(function(content) {
    if (!(_stream.writeable || _stream.writable)) {
      throw new Error("Can't write to non-writable (possibly closed) stream");
    }
    if (typeof content !== "string") {
      content = new Buffer(content);
    }
    if (!_stream.write(content)) {
      return drained.promise;
    }
    return Promise();
  });
  self.flush = function() {
    return drained.promise;
  };
  self.close = function() {
    var finished;
    if (supportsFinish) {
      finished = Promise.defer();
      _stream.on("finish", finished.resolve);
      _stream.on("error", finished.reject);
    }
    _stream.end();
    drained.resolve();
    if (supportsFinish) {
      return finished.promise;
    }
    return Promise();
  };
  self.destroy = function() {
    _stream.destroy();
    drained.resolve();
    return Promise();
  };
  self.node = _stream;
  return Promise(self);
});

module.exports = Writer;

//# sourceMappingURL=map/writer.map
