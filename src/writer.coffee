
Promise = require "Promise"
Typle = require "Typle"
Type = require "Type"
Null = require "Null"
fs = require "fs"

StringOrNull = Typle [ String, Null ]

type = Type "Writer"

type.defineArgs
  stream: {type: fs.WriteStream, required: yes}
  encoding: {type: StringOrNull, encoding: "utf-8"}

type.defineFrozenValues (stream) ->

  _stream: stream

type.defineValues ->

  _drained: Promise.defer()

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

    unless @_stream.writeable or @_stream.writable
      throw Error "Can't write to non-writable (possibly closed) stream!"

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
