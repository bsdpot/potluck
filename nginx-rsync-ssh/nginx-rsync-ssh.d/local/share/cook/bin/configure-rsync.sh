#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# copy over rsyncd.conf if copied in
if [ -f /root/rsyncd.conf ]; then
    cp -f /root/rsyncd.conf /usr/local/etc/rsync/rsyncd.conf
else
    echo "There is no /root/rsyncd.conf file"
fi
