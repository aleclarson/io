
# TODO: Rewrite without "qfs"

Promise = require "Promise"
define = require "define"
globby = require "globby"
qfs = require "q-io/fs"

define exports,

  match: (globs) ->
    globby globs

  read: Promise.wrap (path) ->
    qfs.read path

  write: Promise.wrap (path, contents) ->
    qfs.write path, contents

  append: Promise.wrap (path, contents) ->
    qfs.append path, contents

  exists: Promise.wrap (path) ->
    qfs.exists path

  copy: Promise.wrap (path, dest) ->
    qfs.copyTree path, dest

  move: Promise.wrap (path, dest) ->
    qfs.move path, dest

  remove: Promise.wrap (path) ->
    qfs.removeTree path

  makeDir: Promise.wrap (path) ->
    qfs.makeTree path

  readDir: Promise.wrap (path) ->
    qfs.list path

  isDir: Promise.wrap (path) ->
    qfs.isDirectory path

  isFile: Promise.wrap (path) ->
    qfs.isFile path

  stats: Promise.wrap (path) ->
    qfs.stat path
