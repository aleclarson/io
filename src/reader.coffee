
emptyFunction = require "emptyFunction"
Promise = require "Promise"
Type = require "Type"
Null = require "Null"
fs = require "fs"

type = Type "Reader"

type.defineArgs ->

  required: yes
  types:
    stream: fs.ReadStream
    encoding: String.or Null

  defaults:
    encoding: "utf-8"

type.defineFrozenValues (options) ->

  _stream: options.stream

  _encoding: options.encoding

  _end: Promise.defer()

  _chunks: []

type.defineValues ->

  _receiver: @_defaultReceiver

type.initInstance ->

  if @_encoding and @_stream.setEncoding
    @_stream.setEncoding @_encoding

  @_stream.on "error", (error) =>
    @_end.reject error

  @_stream.on "end", =>
    @_end.resolve()

  @_stream.on "data", (chunk) =>
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
