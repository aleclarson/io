
assertType = require "assertType"
rimraf = require "rimraf"
mkdirp = require "mkdirp"
globby = require "globby"
define = require "define"
assert = require "assert"
iconv = require "iconv-lite"
path = require "path"
fs = require "fs"

UTF8 = "utf8"

sync =

#
# Testing existence
#

  exists: (filePath) ->
    assertType filePath, String
    filePath = path.resolve filePath
    return fs.existsSync filePath

  isFile: (filePath) ->
    assertType filePath, String
    filePath = path.resolve filePath
    return sync.exists(filePath) and
      sync.stats(filePath).isFile()

  isDir: (filePath) ->
    assertType filePath, String
    filePath = path.resolve filePath
    return sync.exists(filePath) and
      sync.stats(filePath).isDirectory()

#
# Reading data
#

  match: (globs, options) ->
    assertType globs, [ String, Array ]
    return globby.sync globs, options

  readDir: (filePath) ->
    assertType filePath, String
    filePath = path.resolve filePath
    assert sync.isDir(filePath), "'filePath' must be an existing directory!"
    return fs.readdirSync filePath

  read: (filePath, options = {}) ->
    assertType filePath, String
    assertType options, Object
    assert sync.isFile(filePath), "'filePath' must be an existing file!"
    contents = fs.readFileSync filePath
    if options.encoding isnt null
      contents = iconv.decode contents, options.encoding or UTF8
      contents = contents.slice 1 if contents.charCodeAt(0) is 0xFEFF
    return contents

  stats: (filePath) ->
    assertType filePath, String
    filePath = path.resolve filePath
    return fs.statSync filePath

#
# Mutating data
#

  makeDir: (filePath) ->
    assertType filePath, String
    filePath = path.resolve filePath
    assert not sync.isFile(filePath), "'filePath' must be a directory or not exist!"
    return mkdirp.sync filePath

  write: (filePath, contents, options = {}) ->

    assertType filePath, String
    filePath = path.resolve filePath
    assert not sync.isDir(filePath), "'filePath' cannot be a directory!"

    # Create any missing parent directories.
    sync.makeDir path.dirname filePath

    assertType contents, [ String, Buffer ]
    options.encoding ?= UTF8 if not Buffer.isBuffer contents
    contents = iconv.encode contents, options.encoding
    fs.writeFileSync filePath, contents, options
    return

  append: (filePath, contents) ->

    assertType filePath, String
    filePath = path.resolve filePath
    assert not sync.isDir(filePath), "'filePath' cannot be a directory!"

    # Create the file if it does not exist.
    if not sync.exists filePath
      return sync.write filePath, contents

    assertType contents, [ String, Buffer ]
    options.encoding ?= UTF8 if not Buffer.isBuffer contents
    contents = iconv.encode contents, options.encoding
    fs.appendFileSync filePath, contents, options
    return

  # Options:
  #   - force (Boolean): If true, avoid throwing when `destPath` already exists
  #   - recursive (Boolean): If true, copy directories recursively (defaults to only copying files)
  #   - testRun (Boolean): If true, print actions to console instead of actually doing them
  copy: (filePath, destPath, options = {}) ->

    assertType filePath, String
    assertType destPath, String
    assertType options, Object

    filePath = path.resolve filePath
    destPath = path.resolve destPath

    assert sync.exists(filePath), "'filePath' must exist!"

    if sync.isDir filePath

      if options.testRun
        if not sync.exists destPath
          console.log "Creating '#{destPath}'"

      # Copy the directory even if it's empty.
      else sync.makeDir destPath

      return sync.readDir(filePath).forEach (childName) ->
        childPath = path.join filePath, childName
        return if sync.isDir(childPath) and not options.recursive
        childDest = path.join destPath, childName
        sync.copy childPath, childDest, options

    # Force an overwrite by setting `options.force` to true.
    assert options.force or not sync.exists(destPath), "'destPath' must not exist!"

    if options.testRun
      console.log "Copying '#{filePath}' to '#{destPath}'"
      return

    sync.write destPath, sync.read filePath
    return

  move: (filePath, destPath) ->

    assertType filePath, String
    assertType destPath, String

    filePath = path.resolve filePath
    destPath = path.resolve destPath

    assert sync.exists(filePath), "'filePath' must exist!"
    assert not sync.exists(destPath), "'destPath' must not exist!"

    # Create missing parent directories.
    sync.makeDir path.dirname destPath

    fs.renameSync filePath, destPath
    return

  remove: (filePath) ->

    assertType filePath, String

    filePath = path.resolve filePath
    return no if not sync.exists filePath

    rimraf.sync filePath
    return yes

define exports, sync
