#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e

# enable redis_exporter service
service redis_exporter enable || true
echo "redis_exporter_listen_address=\"$IP:9121\"" >> /etc/rc.conf
echo "redis_exporter_server=\"$IP\"" >> /etc/rc.conf

if [ -n "$AUTHPASS" ]; then
	echo "redis_exporter_args=\"-redis.password $AUTHPASS\"" >> /etc/rc.conf
fi
