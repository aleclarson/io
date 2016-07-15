
emptyFunction = require "emptyFunction"
fromArgs = require "fromArgs"
Promise = require "Promise"
Null = require "Null"
Type = require "Type"
fs = require "fs"

# Wraps a Node readable stream, providing an API similar
# to a Narwhal synchronous `io` stream except returning
# promises for long latency operations.
type = Type "Reader"

type.argumentTypes =
  stream: fs.ReadStream
  encoding: [ String, Null ]

type.argumentDefaults =
  encoding: "utf-8"

type.defineFrozenValues

  _stream: fromArgs 0

  _encoding: fromArgs 1

  _end: -> Promise.defer()

  _chunks: -> []

type.defineValues

  _receiver: -> @_defaultReceiver

type.initInstance (stream, encoding) ->

  if encoding and stream.setEncoding
    stream.setEncoding encoding

  stream.on "error", (error) =>
    @_end.reject error

  stream.on "end", =>
    @_end.resolve()

  stream.on "data", (chunk) =>
    @_receiver chunk

type.defineMethods

  read: ->
    @_receiver = @_defaultReceiver
    @_end.promise.then =>
      @_receiver = emptyFunction
      contents = @_read()
      @_chunks.length = 0
      return contents

  forEach: (receiver) ->

    @_receiver = receiver

    if @_chunks.length
      receiver @_read()
      @_chunks.length = 0

    @_end.promise.always =>
      @_receiver = emptyFunction
      return

  close: ->
    @_stream.destroy()
    return

  _defaultReceiver: (chunk) ->
    @_chunks.push chunk

  _read: ->
    return @_join() unless @_encoding
    return @_chunks.join ""

  _join: ->
    chunks = @_chunks
    count = chunks.length

    length = 0
    index = -1
    while ++index < count
      length += chunks[index].length

    chunk = new Buffer length

    offset = 0
    index = -1
    while ++index < count
      chunks[index].copy chunk, offset, 0
      offset += chunks[index].length

    return chunk

module.exports = type.build()
