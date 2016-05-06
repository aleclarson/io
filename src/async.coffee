
define = require "define"
globby = require "globby"
qfs = require "q-io/fs"
q = require "q"

define exports,

  match: (globs) ->
    q.nfcall globby, globs

  read: (path) ->
    qfs.read path

  write: (path, contents) ->
    qfs.write path, contents

  append: (path, contents) ->
    qfs.append path, contents

  exists: (path) ->
    qfs.exists path

  copy: (path, dest) ->
    qfs.copyTree path, dest

  move: (path, dest) ->
    qfs.move path, dest

  remove: (path) ->
    qfs.removeTree path

  makeDir: (path) ->
    qfs.makeTree path

  readDir: (path) ->
    qfs.list path

  isDir: (path) ->
    qfs.isDirectory path

  isFile: (path) ->
    qfs.isFile path

  stats: (path) ->
    qfs.stat path
