#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

# make sure we have /root/bin
mkdir -p /root/bin

# copy in custom backup script
< "$TEMPLATEPATH/pgbak.sh.in" \
  sed "s${sep}%%pgbakpath%%${sep}$DUMPPATH${sep}g" \
  > /root/bin/pgbak.sh

# set executable permissions
chmod 755 /root/bin/pgbak.sh

# setup cronjob
echo "${DUMPSCHEDULE}       root   /usr/bin/nice -n 20 /root/bin/pgbak.sh" >> /etc/crontab
