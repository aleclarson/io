
assertType = require "assertType"
Either = require "Either"
rimraf = require "rimraf"
mkdirp = require "mkdirp"
globby = require "globby"
iconv = require "iconv-lite"
path = require "path"
fs = require "fs"

UTF8 = "utf8"

StringOrArray = Either String, Array
StringOrBuffer = Either String, Buffer
StringOrNumber = Either String, Number

#
# Files
#

isFile = (filePath) ->
  assertType filePath, String
  try # The line below throws when nothing exists at the given path.
    passed = fs.statSync(filePath).isFile()
  return passed is yes

readFile = (filePath, options = {}) ->

  assertType filePath, String
  assertType options, Object

  if not isFile filePath
    throw Error "'filePath' must be an existing file: " + path.resolve filePath

  contents = fs.readFileSync filePath
  if options.encoding isnt null
    contents = iconv.decode contents, options.encoding or UTF8
    contents = contents.slice 1 if contents.charCodeAt(0) is 0xFEFF
  return contents

writeFile = (filePath, contents, options = {}) ->

  assertType filePath, String
  assertType contents, StringOrBuffer
  assertType options, Object

  if isDir filePath
    throw Error "'filePath' cannot be a directory: " + path.resolve filePath

  # Create any missing parent directories.
  writeDir path.dirname path.resolve filePath

  if not Buffer.isBuffer contents
    options.encoding ?= UTF8

  contents = iconv.encode contents, options.encoding
  fs.writeFileSync filePath, contents, options
  return

appendFile = (filePath, contents) ->

  assertType filePath, String
  assertType contents, StringOrBuffer

  if isDir filePath
    throw Error "'filePath' cannot be a directory: " + path.resolve filePath

  # Create the file if it does not exist.
  if not exists filePath
    return writeFile filePath, contents

  if not Buffer.isBuffer contents
    options.encoding ?= UTF8

  contents = iconv.encode contents, options.encoding
  fs.appendFileSync filePath, contents, options
  return

#
# Directories
#

isDir = (filePath) ->
  assertType filePath, String
  try # The line below throws when nothing exists at the given path.
    passed = fs.statSync(filePath).isDirectory()
  return passed is yes

readDir = (dirPath) ->
  assertType dirPath, String
  if not isDir dirPath
    throw Error "'dirPath' must be an existing directory: " + path.resolve dirPath
  return fs.readdirSync dirPath

writeDir = (dirPath) ->
  assertType dirPath, String
  if isFile dirPath
    throw Error "'dirPath' must be a directory or not exist: " + path.resolve dirPath
  return mkdirp.sync dirPath

#
# Symlinks
#

isLinkBroken = (linkPath) ->
  assertType linkPath, String
  if not isLink linkPath
    throw Error "'linkPath' must be a symbolic link: " + path.resolve linkPath
  linkParent = path.dirname linkPath
  targetPath = path.resolve linkParent, readLink linkPath
  return not exists targetPath

isLink = (filePath) ->
  assertType filePath, String
  try # The line below throws when nothing exists at the given path.
    passed = fs.lstatSync(filePath).isSymbolicLink()
  return passed is yes

readLink = (linkPath) ->
  assertType linkPath, String
  return fs.readlinkSync linkPath

writeLink = (linkPath, targetPath) ->

  assertType linkPath, String
  if isLink linkPath
    rimraf.sync linkPath

  else if exists linkPath
    throw Error "'linkPath' must be a symlink or not exist: " + path.resolve linkPath

  assertType targetPath, String
  targetPath = path.resolve linkPath, targetPath
  if not exists targetPath
    throw Error "'targetPath' must exist: " + targetPath

  fs.symlinkSync targetPath, linkPath
  return

#
# Permissions
#

checkPermissions = (mode) -> (filePath) ->
  assertType filePath, String
  try fs.accessSync filePath, mode
  catch error
    return no
  return yes

isReadable = checkPermissions fs.R_OK
isWritable = checkPermissions fs.W_OK
isExecutable = checkPermissions fs.X_OK

#
# General
#

exists = (filePath) ->
  assertType filePath, String
  try # The line below throws when nothing exists at the given path.
    stats = fs.lstatSync filePath
  return stats isnt undefined

match = (globs, options) ->
  assertType globs, StringOrArray
  assertType options, Object.Maybe
  return globby.sync globs, options

readStats = (filePath) ->
  assertType filePath, String
  try fs.lstatSync filePath
  catch error
    throw Error "'filePath' does not exist: " + path.resolve filePath

setMode = (filePath, mode = "755") ->

  assertType filePath, String
  if not exists filePath
    throw Error "'filePath' must exist: " + path.resolve filePath

  assertType mode, StringOrNumber
  if typeof mode is "string"
    mode = parseInt mode, 8

  fs.chmodSync filePath, mode
  return

copyTree = (fromPath, toPath, options = {}) ->
  # force (Boolean): If true, avoid throwing when `toPath` already exists
  # recursive (Boolean): If true, copy directories recursively (defaults to only copying files)
  # testRun (Boolean): If true, print actions to console instead of actually doing them

  assertType fromPath, String
  assertType toPath, String
  assertType options, Object

  fromPath = path.resolve fromPath
  toPath = path.resolve toPath

  if not exists fromPath
    throw Error "Expected 'fromPath' to exist: " + path.resolve fromPath

  if isDir fromPath

    # Copy the directory even if it's empty.
    if not options.testRun
      writeDir toPath

    else if not exists toPath
      console.log "Creating '#{path.resolve toPath}'"

    return readDir(fromPath).forEach (child) ->
      fromChild = path.join fromPath, child
      return if isDir(fromChild) and not options.recursive
      toChild = path.join toPath, child
      copyTree fromChild, toChild, options

  # Force an overwrite by setting `options.force` to true.
  unless options.force or not exists toPath
    throw Error "Expected 'toPath' to not exist: '#{path.resolve toPath}'"

  if not options.testRun
    writeFile toPath, readFile fromPath
  else
    console.log "Copying '#{path.resolve fromPath}' to '#{path.resolve toPath}'"
  return

moveTree = (fromPath, toPath) ->

  assertType fromPath, String
  assertType toPath, String

  if not exists fromPath
    throw Error "Expected 'fromPath' to exist: '#{path.resolve fromPath}'"

  if exists toPath
    throw Error "Expected 'toPath' to not exist: '#{path.resolve toPath}'"

  # Create missing parent directories.
  writeDir path.dirname path.resolve toPath
  fs.renameSync fromPath, toPath
  return

removeTree = (filePath) ->
  assertType filePath, String
  if exists filePath
    rimraf.sync filePath
    return yes
  return no

#
# Exports
#

module.exports = {

  # Files
  isFile
  read: readFile
  write: writeFile
  append: appendFile

  # Directories
  isDir
  readDir
  writeDir

  # Symlinks
  isLinkBroken
  isLink
  readLink
  writeLink

  # Permissions
  isReadable
  isWritable
  isExecutable

  # General
  exists
  match
  readStats
  setMode
  copy: copyTree
  move: moveTree
  remove: removeTree

  # These will be deprecated in the future.
  link: writeLink
  chmod: setMode
  stats: readStats
  makeDir: writeDir
}
