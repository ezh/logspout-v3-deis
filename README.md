# logspout-v3-deis

__logspout-v3-deis__ is a Go-based module for use with [logspout](https://github.com/gliderlabs/logspout) v3.

This module is currently _proposed_ for use within the Deis platform as a means of introducing Deis-specific functionality into a custom build of the logspout [Docker](https://www.docker.com/) image _without_ requiring the Deis project to fork upstream logspout.

__Note that this is _not_ the source of the `deis-logspout` component itself.__

## Features

logspout-v3-deis implements the following custom logspout components:

* `deisConfigJob`: discovers the address of the log server (e.g. `deis-logger`, which is a simple log aggregator) using [etcd](https://coreos.com/etcd/) (which is required for Deis).  After initial setup, the job continues to poll etcd at one minute intervals and will update logspout's internal configuration if the address of the log server changes.
* `deisLogAdapter`: emits log messages in the custom format expected by the `deis-logger` component.  Internally, this delegates transport to...
* `deisTransport`: this is a simplified version of logspout v3's built in `udpTransport`.

__Note that only UDP transport is supported at this time, but support for TCP is already planned.__

## Using

To use this module, two things must be done:

1. A [Dockerfile](https://docs.docker.com/reference/builder/) must be created.
2. A `modules.go` file must be created.

The only requirement for the `Dockerfile` is that is uses upstream logspout's Docker image as a starting point:

```
FROM gliderlabs/logspout:master
```

__Note that as of this writing, logspout v3 is unreleased, hence the reference to "master" above.__

In the same directory, a minimal `modules.go` looks as follows:

```
package main

import (
	_ "github.com/deis/logspout-v3-deis/deis"
)

```

Executing a Docker build as in the following example will result in a small Docker image with upstream logspout compiled along with logspout-v3-deis, which will automatically be enabled:

```
docker build . -t my/logspout:custom
```

For more information on this process, consult logspout's own [documentation](https://github.com/gliderlabs/logspout/tree/master/custom).

__Note this is the exact process by which it is proposed future versions of the `deis-logspout` component will be built.__

## Contributing

### An important note

Because logspout-v3-deis is implemented as a Go library, custom builds of logspout that include this module acquire the module's code through the use of the `go get` tool.  `go get` is a _simple_, distributed dependency resolver and incorporates no built-in notion of package versioning.  As such, each build that references `github.com/deis/logspout-v3-deis/deis` will acquire logspout-v3-deis from the _HEAD_ of this repository's master branch.

The implication of the above is that this repository subscribes to the stable HEAD philosophy-- meaning the HEAD of the master branch is production worthy at all times.  This also means:

* Development work is _always_ undertaken in feature branches.
* Nothing is ever, _ever_ merged to master without passing CI.
* Breaking changes necessitate a new repository.

If, for instance, logspout v4 should arrive on the scene one day and includes breaking changes that in turn require breaking changes to this module, this module would be forked as `deis/logspout-v4-deis` in order to preserve the HEAD of `deis/logspout-v3-deis` for use with custom logspout builds based upon logspout v3.

### Hacking

It is not necessary to run a Deis cluster in order to hack on logspout-v3-deis.  All that is required is:

* A properly configured Go development environment with Go 1.4 or higher
* Docker 1.5 or higher
* Other build essentials, such a `make`

logspout does not run in a vacuum.  To do anything useful, it must be able to attach to other containers to read their `STDOUT` and forward log messages found therein to a log server.  Additionally, since logspout-v3-deis utilizes etcd for log server discovery, etcd must also be running.

In order to satisfy the dependencies noted above, logspout-v3-deis comes equipped with `make` tasks for running etcd and `deis-logger` "fixtures" during development and testing.


#### etcd

To start a single node etcd cluster:

```
make start-test-ectd
```

This will start etcd in a daemonized Docker container.

To stop this:

```
make stop-test-ectd
```

#### deis-logger

To start `deis-logger`:

```
make run-test-log-server
```

This launches `deis-logger` as a _non_-daemonized container since it is useful to observe this component's output during development and testing.

To stop this container, interrupt it with `ctrl-c`.

#### Building and running logspout-v3-deis

To build logspout-v3-deis:

```
make dev-build
```

To run:

```
make dev-run
```

These are often done in a single line:

```
make dev-build dev-run
```

The running container can be stopped by interrupting it with `ctrl-c`.

__Note the build process used in the examples above produces a larger Docker image.  It is suitable for development use, but is _not_ the process that is used to build a custom Docker image of logspout v3 with logspout-v3-deis.  (See earlier section on use for more information on the correct procedure).  The unsuitability of this build process for creating production-worthy Docker images is the reason the `make` task is prefixed with `dev-`.__

### Commit message hook

This project also includes a git commit hook capable of asserting a commit message's compliance with project standards.  To install:

```
make commit-hook
```