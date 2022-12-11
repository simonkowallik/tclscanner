# tclscanner

[![ci status](https://github.com/simonkowallik/tclscanner/actions/workflows/ci.yaml/badge.svg)](https://github.com/simonkowallik/tclscanner/actions/workflows/ci.yaml)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/simonkowallik/tclscanner)

## Intro

This docker image implements a wrapper around [tclscan](https://github.com/aidanhs/tclscan).
It uses a patched version of [tclscan](https://github.com/simonkowallik/tclscan).

What it does is:
- It wraps tclscan for better support of scanning iRules
- It provides assistance with scanning many files (recursive directory scans)

## Warning

***Please understand that tclscanner can't guarantee code quality or safety in any way. You are solely responsible for your code safety and quality.***


## What is tclscan

tclscan is a tool written in rust lang to scan tcl code for [potentially dangerous double substitution](https://wiki.tcl-lang.org/page/double+substitution) issues.

See: [tclscan](https://github.com/aidanhs/tclscan) and [wiki.tcl-lang.org/page/double+substitution](https://wiki.tcl-lang.org/page/double+substitution)

## What is tclscanner

`tclscanner` is a wrapper for `tclscan` written in python 3. It processes many tcl source code files at once, copies them one-by-one to temporary files in the container and reformats them to `tclscan` to work best. Then it generates a report in json format based on the `tclscan` results.

`tclscanner.py` walks a given directory recursively and scans all files, by default this is the current working directory `.`. The `tclscanner` container uses `/scandir` within the container as the default directory, hence it is advised to map your source code repo to `/scandir` (see examples below).

`tclscanner.py` can be limited to specific file extensions, again see below for examples.

`tclscanner.py` also allows to scan a single file.

## Usage

First have a look at the help file of tclscanner:
```sh
docker run --rm -i simonkowallik/tclscanner tclscanner.py --help

usage: tclscanner [-h] [--file [FILE]] [-d DIRECTORY] [-f [FILE_EXTENSIONS ...]] [--code-convert-only CODE_CONVERT_ONLY]

`tclscanner` is a wrapper for `tclscan`.

options:
  -h, --help            show this help message and exit
  --file [FILE]         analyze provided file
  -d DIRECTORY, --directory DIRECTORY
                        base directory to scan recursively
  -f [FILE_EXTENSIONS ...], --file-extensions [FILE_EXTENSIONS ...]
                        filter for file extensions (case insensitive, default is to scan all files)
  --code-convert-only CODE_CONVERT_ONLY
                        only convert code for the specified file (prints to stdout)

LICENSE: MIT, homepage: https://github.com/simonkowallik/tclscanner
```

For a simple test just run the container in interactive mode (`-i`), this will run `tclscanner.py` with default options against three test files included in the container's `/scandir`:

```sh
docker run --rm -i simonkowallik/tclscanner tclscanner.py | jq | jq .
```

This will produce the following json outout which gives you an idea of the report format:

```json
{
  "./dangerous.tcl": {
    "errors": [],
    "warnings": [
      "Unquoted expr element:1 code:expr 1 + $one",
      "Unquoted expr element:+ code:expr 1 + $one"
    ],
    "dangerous": [
      "Dangerous unquoted expr element:$one code:expr 1 + $one"
    ]
  },
  "./ok.tcl": {
    "errors": [],
    "warnings": [],
    "dangerous": []
  },
  "./warning.tcl": {
    "errors": [],
    "warnings": [
      "Unquoted expr element:1 code:expr 1 + 1",
      "Unquoted expr element:+ code:expr 1 + 1",
      "Unquoted expr element:1 code:expr 1 + 1"
    ],
    "dangerous": []
  }
}
```

`tclscan` is also available in the container:

```sh
docker run --rm -i simonkowallik/tclscanner tclscan

Invalid arguments.

Usage: tclscan check [--no-warn] ( - | <path> )
    tclscan parsestr ( - | <script-str> )
```

## Run tclscanner against your own tcl code

For example scan all files in directory `$HOME/mytclcode`:
```sh
docker run --rm -i -v $HOME/mytclcode:/scandir:ro simonkowallik/tclscanner
```

Scan only files with extensions `tcl` and `txt` in directory `$HOME/mytclcode`:
```sh
docker run --rm -i -v $HOME/mytclcode:/scandir:ro simonkowallik/tclscanner tclscanner.py --file-extensions tcl txt
```

Limit the scan to a subdirectory of `$HOME/projects`:
```sh
docker run --rm -i -v $HOME/projects:/scandir:ro simonkowallik/tclscanner tclscanner.py --file-extensions tcl txt --directory ./tclsourcecode
```

Limit the scan to a single iRule (`myirule.iRule`) within `$HOME/irules`:
```sh
docker run --rm -i -v $HOME/irules:/scandir:ro simonkowallik/tclscanner tclscanner.py --file myirule.iRule
```

## ghcr.io

The container image is also available via [ghcr.io]([ghcr.io](https://github.com/simonkowallik/tclscanner/pkgs/container/tclscanner)).

## Problems / ideas?

If you have any problems or ideas, let me know!
Just open a [github issue](https://github.com/simonkowallik/tclscanner/issues).
