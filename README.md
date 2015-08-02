# NAME

svsh - Process supervision shell for Perp/S6/Runit

# DESCRIPTION

`svsh` is a command line shell for process supervision suites of the [daemontools](http://cr.yp.to/daemontools.html) family. Currently, it supports
[perp](http://b0llix.net/perp/), [s6](http://www.skarnet.org/software/s6/index.html)
and [runit](http://smarden.org/runit/) (yes, ironically `daemontools` is not supported
yet). It provides a unified interface allowing easy inspection and manipulation of services
(i.e. processes) managed by supported supervision suites.

`scsh` does not require any configurations or changes to your suite's service directories;
just point it at a base directory and you immediately get a usable shell, listing all
services and their statuses, and accepting commands to perform on them.

The shell provides a very simple syntax that is easy to remember, far simpler than the
particular syntax of the underlying tools provided by the supervision suite itself. Instead
of having to execute `perpctl -b /services q nginx` to restart an nginx service running from
`/services/nginx`, just execute `restart nginx`. Couldn't be simpler.

![screenshot](https://ido50.github.io/Svsh/screenshot.png)
