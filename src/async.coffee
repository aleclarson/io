
# TODO: Rewrite without "q-io/fs"

Promise = require "Promise"
define = require "define"
globby = require "globby"
qfs = require "q-io/fs"
fs = require "fs"

async =

#
# Testing existence
#

  exists: Promise.wrap (path) ->
    qfs.exists path

  isFile: Promise.wrap (path) ->
    qfs.isFile path

  isDir: Promise.wrap (path) ->
    qfs.isDirectory path

#
# Reading data
#

  match: (globs, options) ->
    globby globs, options

  readDir: Promise.wrap (path) ->
    qfs.list path

  read: Promise.wrap (path) ->
    qfs.read path

  stats: Promise.ify fs.stat

#
# Mutating data
#

  makeDir: Promise.wrap (path) ->
    qfs.makeTree path

  write: Promise.wrap (path, contents) ->
    qfs.write path, contents

  append: Promise.wrap (path, contents) ->
    qfs.append path, contents

  copy: Promise.wrap (path, dest) ->
    qfs.copyTree path, dest

  move: Promise.wrap (path, dest) ->
    qfs.move path, dest

  remove: Promise.wrap (path) ->
    qfs.removeTree path

define exports, async
