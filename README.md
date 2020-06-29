# potluck

## Overview

This project contains the FreeBSD *pot* (jail) (```pkg install pot```) flavours which are regularly built with Jenkins and published on [potluck.honeyguide.net](https://potluck.honeyguide.net).

To learn about pot & pot flavours, go to [pot.pizzamig.dev](https://pot.pizzamig.dev).

To learn how to use these pot flavours & images (spoiler alert: it is just one command...), go to [potluck.honeyguide.net](https://potluck.honeyguide.net).

*Please note:*

**Additional flavours or fixes/updates to existing flavours are very welcome via pull requests!**

If you want to provide an additional flavour, please provide one or both "flavour" and "flavour".sh files as well as a short README.md.

If you have more than one flavour that needs to be chained (e.g. to modify the jail to be non-returning for ```nomad```), you can also add up to four additional "flavour-1"/"flavour-1.sh", "flavour-2" etc. files. They will be processed in the right order by Jenkins.

If you do have any questions or comments, do not hesitate to contact us!

## Technical notes about flavours

If you prepare flavours for ```nomad```, add the start cmd flavour as flavour+4 to make sure it is run as the last flavour. The start cmd flavour does not allow any further shell scripts to be run because the jail never returns.

If you want to slim your pot jail, create slim.sh as flavour+3 (second to last). Jenkins does not auto-slim flavours, so simply copy slim.sh from ```/usr/local/etc/pot/flavours``` as flavour+3 into github.

See nginx-nomad for example.
