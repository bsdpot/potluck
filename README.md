# potluck

This project contains FreeBSD *pot* (pkg install pot) flavours which are regularly built with Jenkins.

To learn about pot & pot flavours, go to [pot.pizzamig.dev](https://pot.pizzamig.dev).

To learn how to use these pot flavours & images (spoiler alert: it is just one command...), go to [potluck.honeyguide.net](https://potluck.honeyguide.net).

*Please note:*

**Additional flavours or fixes/updates to existing flavours are very welcome via pull requests!**

If you want to provide an additional flavour, please provide one or both "flavour" and "flavour".sh files as well as a short README.md.

If you have more than one flavour that needs to be chained (e.g. to modify the jail to be non-returning for ```nomad```), you can also add up to four additional "flavour-1"/"flavour-1.sh", "flavour-2" etc. files. They will be processed in the right order by Jenkins.
