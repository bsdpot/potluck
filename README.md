# NOTE: THIS REPOSITORY IS NO LONGER MAINTAINED, THE PROJECT HAS MOVED TO https://codeberg.org/bsdpot/potluck

# potluck

## Overview

This project contains the FreeBSD *pot* (jail) (```pkg install pot```) flavours which are regularly built with Jenkins and published on [potluck.honeyguide.net](https://potluck.honeyguide.net).

To learn about pot & pot flavours, go to [pot.pizzamig.dev](https://pot.pizzamig.dev).

To learn how to use these pot flavours & images (spoiler alert: it is just one command...), go to [potluck.honeyguide.net](https://potluck.honeyguide.net).

**Additional flavours or fixes/updates to existing flavours are very welcome via pull requests!**

Please see [CONTRIBUTING.md](https://github.com/bsdpot/potluck/CONTRIBUTING.md) for useful contribution info.

For a relatively easy way to create new flavours based on our code, [see our howto](https://potluck.honeyguide.net/howto/).

If you want to provide an additional flavour, please provide one or both "flavour" and "flavour".sh files as well as a short README.md.

If you have more than one flavour that needs to be chained (e.g. to modify the jail to be non-returning for ```nomad```), you can also add up to four additional "flavour+1"/"flavour+1.sh", "flavour+2" etc. files. They will be processed in the right order by Jenkins.

If you do have any questions or comments, do not hesitate to contact us!
