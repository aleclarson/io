
assertType = require "assertType"
rimraf = require "rimraf"
mkdirp = require "mkdirp"
globby = require "globby"
Typle = require "Typle"
iconv = require "iconv-lite"
path = require "path"
fs = require "fs"

UTF8 = "utf8"

StringOrArray = Typle [ String, Array ]
StringOrBuffer = Typle [ String, Buffer ]

#
# Testing existence
#

exists = (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath
  return fs.existsSync filePath

isFile = (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath
  return exists(filePath) and
    stats(filePath).isFile()

isDir = (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath
  return exists(filePath) and
    stats(filePath).isDirectory()

#
# Reading data
#

stats = (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath
  return fs.statSync filePath

readFile = (filePath, options = {}) ->

  assertType filePath, String
  assertType options, Object

  if not isFile filePath
    throw Error "'filePath' must be an existing file!"

  contents = fs.readFileSync filePath
  if options.encoding isnt null
    contents = iconv.decode contents, options.encoding or UTF8
    contents = contents.slice 1 if contents.charCodeAt(0) is 0xFEFF
  return contents

appendFile = (filePath, contents) ->

  assertType filePath, String
  filePath = path.resolve filePath

  if isDir filePath
    throw Error "'filePath' cannot be a directory!"

  # Create the file if it does not exist.
  if not exists filePath
    return writeFile filePath, contents

  assertType contents, StringOrBuffer
  options.encoding ?= UTF8 if not Buffer.isBuffer contents
  contents = iconv.encode contents, options.encoding
  fs.appendFileSync filePath, contents, options
  return

readTree = (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath

  if not isDir filePath
    throw Error "'filePath' must be an existing directory!"

  return fs.readdirSync filePath

match = (globs, options) ->
  assertType globs, StringOrArray
  assertType options, Object.Maybe
  return globby.sync globs, options

#
# Mutating data
#

writeFile = (filePath, contents, options = {}) ->

  assertType filePath, String
  filePath = path.resolve filePath

  if isDir filePath
    throw Error "'filePath' cannot be a directory!"

  # Create any missing parent directories.
  makeTree path.dirname filePath

  assertType contents, StringOrBuffer
  options.encoding ?= UTF8 if not Buffer.isBuffer contents
  contents = iconv.encode contents, options.encoding
  fs.writeFileSync filePath, contents, options
  return

makeTree = (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath

  if isFile filePath
    throw Error "'filePath' must be a directory or not exist!"

  return mkdirp.sync filePath

# Options:
#   - force (Boolean): If true, avoid throwing when `toPath` already exists
#   - recursive (Boolean): If true, copy directories recursively (defaults to only copying files)
#   - testRun (Boolean): If true, print actions to console instead of actually doing them
copyTree = (fromPath, toPath, options = {}) ->

  assertType fromPath, String
  assertType toPath, String
  assertType options, Object

  fromPath = path.resolve fromPath
  toPath = path.resolve toPath

  if not exists fromPath
    throw Error "Expected 'fromPath' to exist: '#{fromPath}'"

  if isDir fromPath

    if options.testRun
      if not exists toPath
        console.log "Creating '#{toPath}'"

    # Copy the directory even if it's empty.
    else makeTree toPath

    return readTree(fromPath).forEach (child) ->
      fromChild = path.join fromPath, child
      return if isDir(fromChild) and not options.recursive
      toChild = path.join toPath, child
      copyTree fromChild, toChild, options

  # Force an overwrite by setting `options.force` to true.
  unless options.force or not exists toPath
    throw Error "Expected 'toPath' to not exist: '#{toPath}'"

  if options.testRun
    console.log "Copying '#{fromPath}' to '#{toPath}'"
    return

  writeFile toPath, readFile fromPath
  return

moveTree = (fromPath, toPath) ->

  assertType fromPath, String
  assertType toPath, String

  fromPath = path.resolve fromPath
  toPath = path.resolve toPath

  if not exists fromPath
    throw Error "Expected 'fromPath' to exist: '#{fromPath}'"

  if exists toPath
    throw Error "Expected 'toPath' to not exist: '#{toPath}'"

  # Create missing parent directories.
  makeTree path.dirname toPath

  fs.renameSync fromPath, toPath
  return

removeTree = (filePath) ->

  assertType filePath, String

  filePath = path.resolve filePath
  return no if not exists filePath

  rimraf.sync filePath
  return yes

module.exports = {
  exists
  isFile
  isDir
  stats
  read: readFile
  write: writeFile
  append: appendFile
  match
  readDir: readTree
  makeDir: makeTree
  copy: copyTree
  move: moveTree
  remove: removeTree
}
