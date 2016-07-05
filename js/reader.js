var NamedFunction, Promise, Reader;

NamedFunction = require("NamedFunction");

Promise = require("Promise");

Reader = NamedFunction("Reader", function(_stream, charset) {
  var begin, chunks, end, receiver, self, slurp;
  self = Object.create(Reader.prototype);
  if (charset && _stream.setEncoding) {
    _stream.setEncoding(charset);
  }
  begin = Promise.defer();
  end = Promise.defer();
  _stream.on("error", function(reason) {
    return begin.reject(reason);
  });
  chunks = [];
  receiver = null;
  _stream.on("end", function() {
    begin.resolve(self);
    return end.resolve();
  });
  _stream.on("data", function(chunk) {
    begin.resolve(self);
    if (receiver) {
      return receiver(chunk);
    } else {
      return chunks.push(chunk);
    }
  });
  slurp = function() {
    var result;
    result = charset ? chunks.join("") : self.constructor.join(chunks);
    chunks.splice(0, chunks.length);
    return result;
  };
  self.read = function() {
    var promise, ref, resolve;
    receiver = null;
    ref = Promise.defer(), promise = ref.promise, resolve = ref.resolve;
    end.promise.then(function() {
      return resolve(slurp());
    });
    return promise;
  };
  self.forEach = function(write) {
    if (chunks && chunks.length) {
      write(slurp());
    }
    receiver = write;
    return end.promise.then(function() {
      return receiver = null;
    });
  };
  self.close = function() {
    return _stream.destroy();
  };
  self.node = _stream;
  return begin.promise;
});

module.exports = Reader;

//# sourceMappingURL=map/reader.map
