
{ resolve, dirname, relative, join } = require "path"

mkdirp = require "mkdirp"
rimraf = require "rimraf"
globby = require "globby"
define = require "define"
iconv = require "iconv-lite"
fs = require "fs"

defaultEncoding = "utf8"

define sync = exports,

  match: (globs) ->
    globby.sync globs

  read: (path, options = {}) ->
    contents = fs.readFileSync String path
    if options.encoding isnt null
      contents = iconv.decode contents, options.encoding or defaultEncoding
      contents = contents.slice 1 if contents.charCodeAt(0) is 0xFEFF
    contents

  write: (path, contents, options = {}) ->
    sync.makeDir dirname path
    contents = iconv.encode contents, options.encoding ?= defaultEncoding unless Buffer.isBuffer contents
    fs.writeFileSync path, contents, options
    yes

  append: (path, contents) ->
    return no unless sync.exists path
    contents = iconv.encode contents, options.encoding ?= defaultEncoding unless Buffer.isBuffer contents
    fs.appendFileSync path, contents, options
    yes

  exists: (path) ->
    fs.existsSync path

  copy: (path, dest, options = {}) ->
    path = resolve path
    if sync.isFile path
      contents = sync.read path
      if options.force or !sync.exists dest
        if options.testRun then console.log "Copying '#{path}' to '#{dest}'"
        else return sync.write dest, contents, options
      return no
    else if sync.isDir path
      dest = resolve dest
      for child in sync.match path + "/**"
        if sync.isFile child
          childDest = join dest, relative path, child
          sync.copy child, childDest, options
    return

  move: (path, dest) ->
    fs.renameSync path, dest

  remove: (path) ->
    path = String path
    return no unless sync.exists path
    rimraf.sync path
    yes

  makeDir: (path) ->
    mkdirp.sync path

  readDir: (path) ->
    fs.readdirSync path

  isDir: (path) ->
    sync.exists(path) and sync.stats(path).isDirectory()

  isFile: (path) ->
    sync.exists(path) and sync.stats(path).isFile()

  stats: (path) ->
    fs.statSync path
