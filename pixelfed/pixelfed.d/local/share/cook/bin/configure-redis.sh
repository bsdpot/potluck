#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

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

# copy over a redis config file and replace any values
# we're using a socket instead of IP
# the commented out placeholder gets updated anyway
# With mastodon and nextcloud pot instances an external redis instance is used
< "$TEMPLATEPATH/redis.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
> /usr/local/etc/redis.conf

# add user www to the redis group
pw usermod www -G redis

# enable redis
service redis enable || true

# start redis
service redis start || true
