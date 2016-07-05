
emptyFunction = require "emptyFunction"
assertType = require "assertType"
Promise = require "Promise"
globby = require "globby"
assert = require "assert"
path = require "path"
fs = require "fs"

Reader = require "./reader"
Writer = require "./writer"

# Support exponential backoff.
require("graceful-fs").gracefulify(fs)

promised = {
  "stat"
  "lstat"
  "rename"
  "symlink"
  "unlink"
  "readdir"
  "mkdir"
}

Object.keys(promised).forEach (key) ->
  promised[key] = Promise.ify fs[key]

#
# Testing existence
#

exists = (filePath) ->
  onFulfilled = emptyFunction.thatReturnsTrue
  onRejected = emptyFunction.thatReturnsFalse
  promised.stat filePath
  .then onFulfilled, onRejected

isFile = (filePath) ->
  onFulfilled = (stats) -> stats.isFile()
  onRejected = emptyFunction.thatReturnsFalse
  promised.stat filePath
  .then onFulfilled, onRejected

isDir = (filePath) ->
  onFulfilled = (stats) -> stats.isDirectory()
  onRejected = emptyFunction.thatReturnsFalse
  promised.stat filePath
  .then onFulfilled, onRejected

#
# Reading data
#

readStats = (filePath) ->
  promised.stat filePath # BUG: Avoid error; only one argument can be passed.

readFile = (filePath, options) ->
  openFile filePath, options
  .then (stream) -> stream.read()

openFile = (filePath, options = {}) ->

  assertType filePath, String
  assertType options, Object

  options.flags ?= "r"

  streamConfig =
    flags: options.flags.replace(/b/g, "") or "r"

  if "bufferSize" in options
    streamConfig.bufferSize = options.bufferSize

  if "mode" in options
    streamConfig.mode = options.mode

  if "begin" in options
    streamConfig.start = options.begin
    streamConfig.end = options.end - 1

  if options.flags.indexOf("b") >= 0
    assert not options.charset, "Cannot open a binary file with a charset: " + options.charset
  else options.charset ?= "utf-8"

  if options.flags.indexOf("w") >= 0 or options.flags.indexOf("a") >= 0
    stream = fs.createWriteStream filePath, streamConfig
    return Writer stream, options.charset

  stream = fs.createReadStream filePath, streamConfig
  return Reader stream, options.charset

readTree = (filePath) ->
  assertType filePath, String
  return promised.readdir filePath

match = (globs, options) ->
  assertType globs, [ String, Array ]
  assertType options, Object.Maybe
  return globby globs, options

#
# Mutating data
#

writeFile = (filePath, value, options = {}) ->

  assertType filePath, String
  assertType value, [ String, Buffer ]
  assertType options, Object

  options.flags ?= "w"
  if options.flags.indexOf("b") >= 0
    unless value instanceof Buffer
      value = new Buffer value
  else if value instanceof Buffer
    options.flags += "b"

  openFile filePath, options
  .then (stream) ->
    stream.write value
    .then stream.close

appendFile = (filePath, value, options = {}) ->

  assertType filePath, String
  assertType value, [ String, Buffer ]
  assertType options, Object

  options.flags ?= "a"
  if options.flags.indexOf("b") >= 0
    unless value instanceof Buffer
      value = new Buffer value
  else if value instanceof Buffer
    options.flags += "b"

  openFile filePath, options
  .then (stream) ->
    stream.write value
    .then stream.close

copyFile = (fromPath, toPath) ->
  assertType fromPath, String
  assertType toPath, String
  promised.stat(fromPath).then (stats) ->
    reader = openFile fromPath, flags: "rb"
    writer = openFile toPath, flags: "wb", mode: stats.node.mode
    Promise.all [ reader, writer ]
    .then ([ reader, writer ]) ->
      reader.forEach writer.write
      .then -> Promise.all [ reader.close(), write.close() ]

makeTree = (filePath, mode = "755") ->

  assertType filePath, String
  assertType mode, [ String, Number ]

  if typeof mode is "string"
    mode = parseInt mode, 8

  promised.mkdir filePath, mode

copyTree = (fromPath, toPath) ->

  assertType fromPath, String
  assertType toPath, String

  promised.stat fromPath
  .then (stats) ->

    if stats.isFile()
      return copyFile fromPath, toPath

    if stats.isDirectory()

      return exists toPath

      # Create any missing directories.
      .then (exists) -> exists or makeTree toPath, stats.node.mode

      .then -> promised.readdir fromPath

      .then (children) ->
        Promise.map children, (child) ->

          if path.isAbsolute child
            child = path.relative fromPath

          fromChild = path.join fromPath, child
          toChild = path.join toPath, child

          return copyTree fromChild, toChild

    if stats.isSymbolicLink()
      return promised.symlink toPath, fromPath, "file"

moveTree = (fromPath, toPath) ->

  assertType fromPath, String
  assertType toPath, String

  rename fromPath, toPath
  .fail (error) ->

    # Handle moving files across devices.
    if error.code is "EXDEV"

      return copyTree fromPath, toPath

      .then -> removeTree fromPath

    throw error

removeTree = (filePath) ->

  assertType filePath, String

  promised.lstat(filePath).then (stats) ->

    if not stats.isDirectory()
      return promised.unlink filePath

    return promised.readdir filePath

    .then (children) ->

      Promise.map children, (child) ->

        if not path.isAbsolute child
          child = path.join filePath, child

        return removeTree child

module.exports = {
  exists
  isFile
  isDir
  stats: readStats
  read: readFile
  open: openFile
  write: writeFile
  append: appendFile
  match
  readDir: readTree
  makeDir: makeTree
  copy: copyTree
  move: moveTree
  remove: removeTree
}
