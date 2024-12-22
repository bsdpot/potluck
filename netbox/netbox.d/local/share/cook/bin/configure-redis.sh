#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH=/usr/local/bin:$PATH

# check we have /mnt/redisdata
mkdir -p /mnt/redisdata

# check permissions
chown -R redis:redis /mnt/redisdata

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

# copy in redis.conf from template, setting IP although we don't use because this redis is localhost only
< "$TEMPLATEPATH/redis.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
> /usr/local/etc/redis.conf

# enable redis
service redis enable
