
Promise = require "Promise"
Either = require "Either"
Type = require "Type"
Null = require "Null"
fs = require "fs"

type = Type "Writer"

type.defineArgs ->

  required: yes
  types:
    stream: fs.WriteStream
    encoding: Either String, Null

  defaults:
    encoding: "utf-8"

type.defineFrozenValues (options) ->

  _stream: options.stream

  _encoding: options.encoding

type.defineValues ->

  _drained: Promise.defer()

type.initInstance ->

  if @_encoding and @_stream.setEncoding
    @_stream.setEncoding @_encoding

  @_stream.on "error", (error) =>
    @_drained.reject error
    @_drained = Promise.defer()

  @_stream.on "drain", =>
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
