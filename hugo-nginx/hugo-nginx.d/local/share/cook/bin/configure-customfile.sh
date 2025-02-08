#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# if the copied-in customfile exists, extract to sitename
if [ -f /root/customfile.tgz ]; then
    /usr/bin/tar -xzf /root/customfile.tgz --directory "/mnt/$SITENAME"
fi
