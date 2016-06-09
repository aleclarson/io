
Promise = require "Promise"
define = require "define"
globby = require "globby"
qfs = require "q-io/fs"

define exports,

  match: (globs) ->
    globby.async globs

  read: (path) ->
    Promise qfs.read path

  write: (path, contents) ->
    Promise qfs.write path, contents

  append: (path, contents) ->
    Promise qfs.append path, contents

  exists: (path) ->
    Promise qfs.exists path

  copy: (path, dest) ->
    Promise qfs.copyTree path, dest

  move: (path, dest) ->
    Promise qfs.move path, dest

  remove: (path) ->
    Promise qfs.removeTree path

  makeDir: (path) ->
    Promise qfs.makeTree path

  readDir: (path) ->
    Promise qfs.list path

  isDir: (path) ->
    Promise qfs.isDirectory path

  isFile: (path) ->
    Promise qfs.isFile path

  stats: (path) ->
    Promise qfs.stat path
