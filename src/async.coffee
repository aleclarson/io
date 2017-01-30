
emptyFunction = require "emptyFunction"
assertType = require "assertType"
Promise = require "Promise"
globby = require "globby"
Typle = require "Typle"
path = require "path"
has = require "has"
fs = require "fs"

Reader = require "./reader"
Writer = require "./writer"

# Support exponential backoff.
require("graceful-fs").gracefulify(fs)

StringOrArray = Typle [ String, Array ]
StringOrBuffer = Typle [ String, Buffer ]
StringOrNumber = Typle [ String, Number ]

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
  assertType filePath, String
  onFulfilled = emptyFunction.thatReturnsTrue
  onRejected = emptyFunction.thatReturnsFalse
  promised.stat filePath
  .then onFulfilled, onRejected

isFile = (filePath) ->
  assertType filePath, String
  onFulfilled = (stats) -> stats.isFile()
  onRejected = emptyFunction.thatReturnsFalse
  promised.stat filePath
  .then onFulfilled, onRejected

isDir = (filePath) ->
  assertType filePath, String
  onFulfilled = (stats) -> stats.isDirectory()
  onRejected = emptyFunction.thatReturnsFalse
  promised.stat filePath
  .then onFulfilled, onRejected

isLink = (filePath) ->
  assertType filePath, String
  onFulfilled = (stats) -> stats.isSymbolicLink()
  onRejected = emptyFunction.thatReturnsFalse
  promised.lstat filePath
  .then onFulfilled, onRejected

#
# Reading data
#

readStats = (filePath) ->
  promised.stat filePath # BUG: Avoid error; only one argument can be passed.

readFile = (filePath, options) ->
  openFile(filePath, options).read()

openFile = (filePath, options = {}) ->

  assertType filePath, String
  assertType options, Object

  config = {}

  if has options, "start"
    config.start = options.start
    config.end = options.end - 1

  if has options, "bufferSize"
    config.bufferSize = options.bufferSize

  encoding = null
  if options.encoding isnt null
    encoding = options.encoding or "utf-8"

  if options.writable

    if has options, "mode"
      config.mode = options.mode

    if options.append
      config.flags = "a"

    stream = fs.createWriteStream filePath, config
    return Writer {stream, encoding}

  stream = fs.createReadStream filePath, config
  return Reader {stream, encoding}

readTree = (filePath) ->
  assertType filePath, String
  return promised.readdir filePath

match = (globs, options) ->
  assertType globs, StringOrArray
  assertType options, Object.Maybe
  return globby globs, options

#
# Mutating data
#

writeFile = (filePath, newValue, options = {}) ->

  assertType filePath, String
  assertType newValue, StringOrBuffer
  assertType options, Object

  if newValue instanceof Buffer
    options.encoding = null

  # Create any missing parent directories.
  makeTree path.dirname filePath

  .then ->
    options.writable = yes
    writer = openFile filePath, options
    writer.write newValue
    .then -> writer.close()

appendFile = (filePath, value, options = {}) ->
  options.append = yes
  writeFile filePath, value, options

copyFile = (fromPath, toPath) ->
  assertType fromPath, String
  assertType toPath, String
  promised.stat(fromPath).then (stats) ->
    reader = openFile fromPath
    writer = openFile toPath, { mode: stats.mode }
    reader.forEach writer.write
    .then -> writer.close()

makeTree = (filePath, mode = "755") ->

  assertType filePath, String
  assertType mode, StringOrNumber

  if typeof mode is "string"
    mode = parseInt mode, 8

  dirPath = path.dirname filePath

  # Create any missing parent directories.
  exists dirPath
  .then (dirExists) ->
    dirExists or makeTree dirPath, mode

  .then ->
    promised.mkdir filePath, mode
    .fail (error) ->
      return if error.code is "EEXIST"
      throw error

copyTree = (fromPath, toPath) ->

  assertType fromPath, String
  assertType toPath, String

  promised.stat fromPath
  .then (stats) ->

    if stats.isSymbolicLink()
      return promised.symlink toPath, fromPath, "file"

    if stats.isFile()
      return copyFile fromPath, toPath

    # Create any missing directories.
    return exists toPath
    .then (exists) ->
      exists or makeTree toPath, stats.node.mode

    .then -> promised.readdir fromPath
    .then (children) ->
      Promise.map children, (child) ->
        fromChild = path.join fromPath, child
        toChild = path.join toPath, child
        return copyTree fromChild, toChild

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
        removeTree path.join filePath, child

module.exports = {
  exists
  isFile
  isDir
  isLink
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
