# Overview

`cronwrap` is a wrapper script for cron jobs, written to mitigate some common
pitfalls of cron jobs on systems I admin, where I tend to not write the jobs
themselves but have to pick up the pieces when things explode.

See [http://www.zomo.co.uk/2010/02/cron/] for more about the motivation. The
key aims are

  * prevent multiple runs of the same job piling up by using a lock
  * store output in a timestamped directory
  * make it easy for external monitoring to determine health of cron jobs

Absent from this incarnation are the SNMP and email hooks that other variants
enjoy.

Comments and criticism welcome.

Two variants are here: `cronwrap.lockf` which uses FreeBSD's `lockf` binary,
and `cronwrap.lockrun` which uses a more cross-platform locker,
[`lockrun`](http://unixwiz.net/tools/lockrun.html)

# Requirements

  * [`lockrun`](http://unixwiz.net/tools/lockrun.html) for `cronwrap.lockrun`
  * for the additional scripts, working `fuser`, `pgrep`/`pkill` and `/proc`
  * jobs to exit non-zero on error

# External bits

  * A (heh) cron job to age out old cronwrap logs
  * A monitoring system to care about the `OK`, `FAIL`, `LOCK` markers

# Usage

See comments within cronwrap for details, but here's an example `cron.d` snippet

  ```
  */5 * * * * nobody cronwrap update-local-cache 300 /usr/local/bin/cache-update -v local
  ```

Here `300` is an interval specification. `cronwrap` itslef doesn't use it but
writes it to the job's status directory as `interval`, so that a monitor can
compare it to the adjacent `last_ran` value.

# Contents

  `cronwrap.lockf`    - wrapper itself
  `cronwrap.lockrun`  - wrapper itself

  `check_cronwrap`    - a Nagios test to guage the health of cronwrapped jobs

  `show-cronwap-log`  - since the output of a running is in a temporary file, it can
                      be hard to find. this script finds it, useful to work out
                      what a long-running job is up to.

  `kill-cronwrap-job` - kills the the job that cronwrap (and thus lockrun) is managing
                      useful to nuke a wedged job that is holding up

  `cronweb.rb`        - diddy Sinarta web app to provide a web view on cronwrap status and logs


The last three are decidedly less portable than the main cronwrap script.

# Thanks

Steve Friedl's nifty `lockrun` tool provides an elegant way to lock jobs from
overlapping. It's way better than any homegrown effort of mine.
http://unixwiz.net/tools/lockrun.html

This version of cronwrap was written mostly on Deluxe Online's dime, so thanks
to them for letting me share it. http://deluxeonline.co.uk/

# License

Relesed under a BSD license, see LICENSE. Non-warranty in there too.

# Author

Jon Stuart, jon@zomo.co.uk, Zomo Technology Ltd, 2010.
