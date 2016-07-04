
NamedFunction = require "NamedFunction"
Promise = require "Promise"

version = process.versions.node.split "."
supportsFinish = version[0] >= 0 and version[1] >= 10

# Wraps a Node writable stream, providing an API similar to
# Narwhal's synchronous `io` streams, except returning and
# accepting promises for long-latency operations.
Writer = NamedFunction "Writer", (_stream, charset) ->

  self = Object.create Writer.prototype

  if charset and _stream.setEncoding
    _stream.setEncoding charset

  drained = Promise.defer()

  _stream.on "error", (reason) ->
    drained.reject reason
    drained = Promise.defer()

  _stream.on "drain", ->
    drained.resolve()
    drained = Promise.defer()

  # Writes content to the stream.
  self.write = Promise.wrap (content) ->

    unless _stream.writeable or _stream.writable
      throw new Error "Can't write to non-writable (possibly closed) stream"

    if typeof content isnt "string"
      content = new Buffer content

    unless _stream.write content
      return drained.promise

    return Promise()

  # Waits for all data to flush on the stream.
  self.flush = ->
    drained.promise

  # Closes the stream, waiting for the internal buffer to flush.
  self.close = ->

    if supportsFinish
      finished = Promise.defer()
      _stream.on "finish", finished.resolve
      _stream.on "error", finished.reject

    _stream.end()
    drained.resolve()

    if supportsFinish
      return finished.promise

    return Promise()

  # Terminates writing on a stream, closing before the internal buffer drains.
  self.destroy = ->
    _stream.destroy()
    drained.resolve()
    return Promise()

  self.node = _stream

  return Promise self

module.exports = Writer
