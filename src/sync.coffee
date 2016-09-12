
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
StringOrNumber = Typle [ String, Number ]

#
# Files
#

isFile = (filePath) ->

  assertType filePath, String
  filePath = path.resolve filePath

  try # The line below throws when nothing exists at the given path.
    return yes if fs.statSync(filePath).isFile()
  return no

readFile = (filePath, options = {}) ->

  assertType filePath, String
  assertType options, Object

  if not isFile filePath
    throw Error "'filePath' must be an existing file: " + filePath

  contents = fs.readFileSync filePath
  if options.encoding isnt null
    contents = iconv.decode contents, options.encoding or UTF8
    contents = contents.slice 1 if contents.charCodeAt(0) is 0xFEFF
  return contents

writeFile = (filePath, contents, options = {}) ->

  assertType filePath, String
  filePath = path.resolve filePath

  if isDir filePath
    throw Error "'filePath' cannot be a directory: " + filePath

  # Create any missing parent directories.
  writeDir path.dirname filePath

  assertType contents, StringOrBuffer
  options.encoding ?= UTF8 if not Buffer.isBuffer contents
  contents = iconv.encode contents, options.encoding
  fs.writeFileSync filePath, contents, options
  return

appendFile = (filePath, contents) ->

  assertType filePath, String
  filePath = path.resolve filePath

  if isDir filePath
    throw Error "'filePath' cannot be a directory: " + filePath

  # Create the file if it does not exist.
  if not exists filePath
    return writeFile filePath, contents

  assertType contents, StringOrBuffer
  options.encoding ?= UTF8 if not Buffer.isBuffer contents
  contents = iconv.encode contents, options.encoding
  fs.appendFileSync filePath, contents, options
  return

#
# Directories
#

isDir = (filePath) ->

  assertType filePath, String
  filePath = path.resolve filePath

  try # The line below throws when nothing exists at the given path.
    return yes if fs.statSync(filePath).isDirectory()
  return no

readDir = (dirPath) ->

  assertType dirPath, String
  dirPath = path.resolve dirPath

  if not isDir dirPath
    throw Error "'dirPath' must be an existing directory: " + dirPath

  return fs.readdirSync dirPath

writeDir = (dirPath) ->

  assertType dirPath, String
  dirPath = path.resolve dirPath

  if isFile dirPath
    throw Error "'dirPath' must be a directory or not exist: " + dirPath

  return mkdirp.sync dirPath

#
# Symlinks
#

isLinkBroken = (linkPath) ->

  assertType linkPath, String
  linkPath = path.resolve linkPath

  if not isLink linkPath
    throw Error "'linkPath' must be a symbolic link: " + linkPath

  try # The line below throws when the link is broken.
    return no if fs.statSync filePath
  return yes

isLink = (filePath) ->

  assertType filePath, String
  filePath = path.resolve filePath

  try # The line below throws when nothing exists at the given path.
    return yes if fs.lstatSync(filePath).isSymbolicLink()
  return no

readLink = (linkPath) ->
  assertType linkPath, String
  linkPath = path.resolve linkPath
  return fs.readlinkSync linkPath

writeLink = (linkPath, targetPath) ->

  assertType linkPath, String
  linkPath = path.resolve linkPath
  if exists linkPath
    rimraf.sync linkPath

  assertType targetPath, String
  if not exists targetPath
    throw Error "'targetPath' must exist: " + targetPath

  fs.symlinkSync targetPath, linkPath
  return

#
# Permissions
#

checkPermissions = (mode) -> (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath
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
  filePath = path.resolve filePath

  try # The line below throws when nothing exists at the given path.
    return yes if fs.lstatSync filePath
  return no

match = (globs, options) ->
  assertType globs, StringOrArray
  assertType options, Object.Maybe
  return globby.sync globs, options

readStats = (filePath) ->
  assertType filePath, String
  filePath = path.resolve filePath
  try fs.lstatSync filePath
  catch error
    throw Error "'filePath' does not exist: " + filePath

setMode = (filePath, mode = "755") ->

  assertType filePath, String
  filePath = path.resolve filePath
  if not exists filePath
    throw Error "'filePath' must exist: " + filePath

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
    throw Error "Expected 'fromPath' to exist: " + fromPath

  if isDir fromPath

    # Copy the directory even if it's empty.
    if not options.testRun
      writeDir toPath

    else if not exists toPath
      console.log "Creating '#{toPath}'"

    return readDir(fromPath).forEach (child) ->
      fromChild = path.join fromPath, child
      return if isDir(fromChild) and not options.recursive
      toChild = path.join toPath, child
      copyTree fromChild, toChild, options

  # Force an overwrite by setting `options.force` to true.
  unless options.force or not exists toPath
    throw Error "Expected 'toPath' to not exist: '#{toPath}'"

  if not options.testRun
    writeFile toPath, readFile fromPath
  else
    console.log "Copying '#{fromPath}' to '#{toPath}'"
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
  writeDir path.dirname toPath

  fs.renameSync fromPath, toPath
  return

removeTree = (filePath) ->

  assertType filePath, String

  filePath = path.resolve filePath
  return no if not exists filePath

  rimraf.sync filePath
  return yes

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
