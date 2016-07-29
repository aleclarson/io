
# io 2.1.0 [![stable](http://badges.github.io/stability-badges/dist/stable.svg)](http://github.com/badges/stability-badges)

Improves `require("fs")` by:

- returning a `Promise` from each async function

- providing a synchronous version of each async function

- providing exponential backoff (via [`graceful-fs`](https://github.com/isaacs/node-graceful-fs))

- providing glob matching (via [`globby`](https:))

- taking inspiration from [`q-io`](https://github.com/kriskowal/q-io)

```coffee
{sync, async} = require "io"

# Alternatively...
sync = require "io/sync"
async = require "io/async"
```

&nbsp;

### Testing existence

```coffee
# Resolves to true if the given path exists.
promise = async.exists filePath

# Resolves to true if the given path is a file.
promise = async.isFile filePath

# Resolves to true if the given path is a directory.
promise = async.isDir filePath
```

&nbsp;

### Reading data

```coffee
# Resolves to the contents of the given file.
# Uses same `options` as `fs.readFileSync()`.
promise = async.read filePath, options

# Resolves to either a Reader or Writer.
# Read `src/reader.coffee` or `src/writer.coffee` for more info.
promise = async.open filePath, options

# Resolves to an instance of `fs.Stats` for the given file.
# https://nodejs.org/api/fs.html#fs_class_fs_stats
promise = async.stats filePath

# Resolves to the paths of the
# immediate children in the given directory.
promise = async.readDir filePath

# Resolves to the paths that matched
# the given glob patterns.
promise = async.match globs, options
```

&nbsp;

### Mutating data

```coffee
# Overwrites the given path with new contents.
# Uses same `options` as `fs.writeFileSync()`.
promise = async.write filePath, value, options

# Appends `value` to the contents of `filePath`.
# If the file does not exist, write a new file.
promise = async.append filePath, value

# Create a new directory (with an optional `mode`).
promise = async.makeDir filePath, mode

# Copy a file or directory to a new location.
# If the directory already exists, prefer the
# `fromPath` files over the `toPath` files.
promise = async.copy fromPath, toPath

# Move a file or directory to a new location.
promise = async.move fromPath, toPath

# Remove a file or directory.
promise = async.remove filePath
```

&nbsp;

**TODO:** Write **more** tests!
