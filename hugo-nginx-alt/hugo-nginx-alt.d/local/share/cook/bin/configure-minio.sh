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

# create minio client directory
mkdir -p /root/.minio-client

# make sure root has a bin directory
mkdir -p /root/bin

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# minio actually wants config.json not client.json
# setting for destination
< "$TEMPLATEPATH/client.json.in" \
  sed "s${sep}%%buckethost%%${sep}$BUCKETHOST${sep}g" | \
  sed "s${sep}%%bucketport%%${sep}$SETBUCKETPORT${sep}g" | \
  sed "s${sep}%%bucketuser%%${sep}$BUCKETUSER${sep}g" | \
  sed "s${sep}%%bucketpass%%${sep}$BUCKETPASS${sep}g" \
  > /root/.minio-client/config.json

# setup diff mirror check script
< "$TEMPLATEPATH/mirrorcheck.sh.in" \
  sed "s${sep}%%sitename%%${sep}$SITENAME${sep}g" | \
  sed "s${sep}%%bucketname%%${sep}$BUCKETNAME${sep}g" \
  > /root/bin/mirrorcheck.sh

# set execute permissions
chmod +x /root/bin/mirrorcheck.sh

# setup mirror sync script
< "$TEMPLATEPATH/mirrorsync.sh.in" \
  sed "s${sep}%%sitename%%${sep}$SITENAME${sep}g" | \
  sed "s${sep}%%bucketname%%${sep}$BUCKETNAME${sep}g" \
  > /root/bin/mirrorsync.sh

# set execute permissions
chmod +x /root/bin/mirrorsync.sh

# setup mirror script cron job
# todo
# jenkins can also run this after a build process