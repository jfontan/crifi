# Parallel Find

This crystal library and command searches files in a path that match a regexp. It parallelizes file walk and matching.

## Installation

```
$ git clone https://github.com/jfontan/parallel-find
$ cd parallel-find
$ shards build --production -Dpreview_mt
```

It builds the command to `bin/pf`

## Usage

```
Usage: pf [options] [pattern] [path]
    -h, --help                       Show help
    -j JOBS, --jobs=JOBS             The number of parallel threads
```

By default lists all files in the current directory. You can use `""` to match all files. For example to find all files in `/` you can run:

```
$ pf "" /
```

If your machine has less than 4 threads or you specify `-j 1` the search will be sequential. By default it tries to use all threads.

## Contributing

1. Fork it (<https://github.com/jfontan/parallel-find/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Javi Fontan](https://github.com/jfontan) - creator and maintainer
