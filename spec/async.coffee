
{async} = require ".."

Random = require "random"
rimraf = require "rimraf"
path = require "path"
fs = require "fs"

tmpdir = __dirname + "/.tmp"
setupTmpdir = ->
  beforeAll -> fs.mkdirSync tmpdir
  afterAll -> rimraf.sync tmpdir

expectDir = (dir) ->
  stats = null
  expect -> stats = fs.statSync dir
    .not.toThrow()
  expect stats and stats.isDirectory()
    .toBe yes

describe "async.makeDir(filePath, mode)", ->

  setupTmpdir()

  it "create a new directory", (done) ->
    dir = tmpdir + "/" + Random.id()
    async.makeDir dir
    .then ->
      expectDir dir
      done()

  it "does nothing if a directory already exists", (done) ->
    dir = tmpdir + "/" + Random.id()
    fs.mkdirSync dir
    expectDir dir
    async.makeDir dir
    .then -> done()

  it "creates any missing parent directories", (done) ->
    parentDir = tmpdir + "/" + Random.id()
    dir = parentDir + "/" + Random.id()
    async.makeDir dir
    .then ->
      expectDir parentDir
      expectDir dir
      done()

describe "async.write(filePath, newValue, options)", ->

  setupTmpdir()

  it "overwrites the contents of `filePath` with the `newValue`", (done) ->
    filePath = tmpdir + "/" + Random.id()
    newValue = "abc"
    async.write filePath, newValue
    .then ->
      value = null
      expect -> value = fs.readFileSync filePath, { encoding: "utf-8" }
        .not.toThrow()
      expect value
        .toBe newValue
      done()

  it "supports buffers", (done) ->
    filePath = tmpdir + "/" + Random.id()
    newValue = new Buffer [ 1, 2, 3 ]
    async.write filePath, newValue
    .then ->
      value = null
      expect -> value = fs.readFileSync filePath, { encoding: null }
        .not.toThrow()
      expect value.equals newValue
        .toBe yes
      done()

describe "async.exists(filePath)", ->

describe "async.isFile(filePath)", ->

describe "async.isDir(filePath)", ->

describe "async.stats(filePath)", ->

describe "async.remove(filePath)", ->

  # it "can remove a file", ->

  # it "can recursively remove a directory", ->
