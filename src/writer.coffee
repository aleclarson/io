
fromArgs = require "fromArgs"
Promise = require "Promise"
assert = require "assert"
Null = require "Null"
Type = require "Type"
fs = require "fs"

# Wraps a Node writable stream, providing an API similar to
# Narwhal's synchronous `io` streams, except returning and
# accepting promises for long-latency operations.
type = Type "Writer"

type.argumentTypes =
  stream: fs.WriteStream
  encoding: [ String, Null ]

type.argumentDefaults =
  encoding: "utf-8"

type.defineFrozenValues

  _stream: fromArgs 0

type.defineValues

  _drained: -> Promise.defer()

type.initInstance (stream, encoding) ->

  if encoding and stream.setEncoding
    stream.setEncoding encoding

  stream.on "error", (error) =>
    @_drained.reject error
    @_drained = Promise.defer()

  stream.on "drain", =>
    @_drained.resolve()
    @_drained = Promise.defer()

type.defineMethods

  write: (newValue) ->
    assert @_stream.writeable or @_stream.writable, "Can't write to non-writable (possibly closed) stream!"
    return Promise() if @_stream.write newValue
    return @_drained.promise

  flush: ->
    return @_drained.promise

  close: ->
    finished = Promise.defer()
    @_stream.on "finish", finished.resolve
    @_stream.on "error", finished.reject
    @_stream.end()
    @_drained.resolve()
    return finished.promise

  destroy: ->
    @_stream.destroy()
    @_drained.resolve()
    return

module.exports = type.build()
