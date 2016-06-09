
mkdirp = require "mkdirp"
rimraf = require "rimraf"
globby = require "globby"
define = require "define"
iconv = require "iconv-lite"
Path = require "path"
FS = require "fs"

defaultEncoding = "utf8"

define sync = exports,

  match: (globs) ->
    globby.sync globs

  read: (path, options = {}) ->
    contents = FS.readFileSync String path
    if options.encoding isnt null
      contents = iconv.decode contents, options.encoding or defaultEncoding
      contents = contents.slice 1 if contents.charCodeAt(0) is 0xFEFF
    return contents

  write: (path, contents, options = {}) ->
    sync.makeDir Path.dirname path
    contents = iconv.encode contents, options.encoding ?= defaultEncoding unless Buffer.isBuffer contents
    FS.writeFileSync path, contents, options
    return yes

  append: (path, contents) ->
    return no unless sync.exists path
    contents = iconv.encode contents, options.encoding ?= defaultEncoding unless Buffer.isBuffer contents
    FS.appendFileSync path, contents, options
    return yes

  exists: (path) ->
    FS.existsSync path

  copy: (path, dest, options = {}) ->
    path = Path.resolve path
    if sync.isFile path
      contents = sync.read path
      if options.force or !sync.exists dest
        if options.testRun then console.log "Copying '#{path}' to '#{dest}'"
        else return sync.write dest, contents, options
      return no
    else if sync.isDir path
      dest = Path.resolve dest
      for child in sync.match path + "/**"
        if sync.isFile child
          childDest = Path.join dest, Path.relative path, child
          sync.copy child, childDest, options
    return

  move: (path, dest) ->
    FS.renameSync path, dest

  remove: (path) ->
    path = String path
    return no unless sync.exists path
    rimraf.sync path
    return yes

  makeDir: (path) ->
    mkdirp.sync path

  readDir: (path) ->
    FS.readdirSync path

  isDir: (path) ->
    sync.exists(path) and sync.stats(path).isDirectory()

  isFile: (path) ->
    sync.exists(path) and sync.stats(path).isFile()

  stats: (path) ->
    FS.statSync path
