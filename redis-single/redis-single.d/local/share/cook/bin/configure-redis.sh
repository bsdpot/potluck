#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# check we have /mnt/redisdata
mkdir -p /mnt/redisdata

# check permissions
chown -R redis:redis /mnt/redisdata

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

# if an authpass has been set, copy in the config with that parameter enabled
# if not set, use the default config file
if [ -n "$AUTHPASS" ]; then
	< "$TEMPLATEPATH/redispass.conf.in" \
	  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
	  sed "s${sep}%%authpass%%${sep}$AUTHPASS${sep}g" \
	> /usr/local/etc/redis.conf
else
	< "$TEMPLATEPATH/redis.conf.in" \
	  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
	> /usr/local/etc/redis.conf
fi

# enable redis
service redis enable || true
