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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# minio is expecting config.json now
# updating for destination
< "$TEMPLATEPATH/client.json.in" \
  sed "s${sep}%%buckethost%%${sep}$BUCKETHOST${sep}g" | \
  sed "s${sep}%%bucketuser%%${sep}$BUCKETUSER${sep}g" | \
  sed "s${sep}%%bucketpass%%${sep}$BUCKETPASS${sep}g" \
  > /root/.minio-client/config.json
