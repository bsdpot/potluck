#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# setup cronjob for once a day 3am
echo "0 3 * * *   root   /root/bin/mirrorsync.sh" >> /etc/crontab
