
NamedFunction = require "NamedFunction"
Promise = require "Promise"

# Wraps a Node readable stream, providing an API similar
# to a Narwhal synchronous `io` stream except returning
# promises for long latency operations.
Reader = NamedFunction "Reader", (_stream, charset) ->

  self = Object.create Reader.prototype

  if charset and _stream.setEncoding
    _stream.setEncoding charset

  begin = Promise.defer()
  end = Promise.defer()

  _stream.on "error", (reason) ->
    begin.reject reason

  chunks = []
  receiver = null

  _stream.on "end", ->
    begin.resolve self
    end.resolve()

  _stream.on "data", (chunk) ->
    begin.resolve self
    if receiver then receiver chunk
    else chunks.push chunk

  slurp = ->
    result =
      if charset then chunks.join ""
      else self.constructor.join chunks
    chunks.splice 0, chunks.length
    return result

  # Reads all of the remaining data from the stream.
  self.read = ->
    receiver = null
    {promise, resolve} = Promise.defer()
    end.promise.then -> resolve slurp()
    return promise

  # Reads and writes all of the remaining data from the stream in chunks.
  self.forEach = (write) ->
    write slurp() if chunks and chunks.length
    receiver = write
    return end.promise.then ->
      receiver = null

  self.close = ->
    _stream.destroy()

  self.node = _stream

  return begin.promise

module.exports = Reader
