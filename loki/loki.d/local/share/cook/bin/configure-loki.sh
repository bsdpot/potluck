#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:"$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# setup directories for loki
mkdir -p /mnt/loki/rules-temp

# shellcheck disable=SC3003
# safe(r) separator for sed
#sep=$'\001'

# loki setup
service loki enable
sysrc loki_args="-frontend.instance-addr=127.0.0.1"
sysrc loki_config=/usr/local/etc/loki-local-config.yaml
sysrc loki_logfile="/mnt/log/loki/loki.log"

# patch startup script
sed -i '' 's/command_args="-p/command_args="-f -p/' \
  /usr/local/etc/rc.d/loki

# prepare logdir
mkdir -p /mnt/log/loki
chown loki:loki /mnt/log/loki

# copy in loki config file
if [ -f /mnt/loki/loki-local-config.yaml.in ]; then
	cp /mnt/loki/loki-local-config.yaml.in \
	  /usr/local/etc/loki-local-config.yaml
else
	cp "$TEMPLATEPATH/loki-local-config.yaml.in" \
	  /usr/local/etc/loki-local-config.yaml
fi

# chown to loki user
chown -R loki:loki /mnt/loki

# promtail setup
service promtail enable
sysrc promtail_config="/usr/local/etc/promtail-local-config.yaml"
sysrc promtail_logfile="/mnt/log/promtail/promtail.log"

# patch startup script
sed -i '' 's/command_args="-p/command_args="-f -p/' \
  /usr/local/etc/rc.d/promtail

# prepare logdir
mkdir -p /mnt/log/promtail
chown promtail:promtail /mnt/log/promtail
if [ -f /mnt/log/positions.yaml ] && \
    [ ! -f /mnt/log/promtail/positions.yaml ]; then
	mv /mnt/log/positions.yaml /mnt/log/promtail/positions.yaml
	chown promtail:promtail /mnt/log/promtail/positions.yaml
fi

# copy in the promtail config file
if [ -f /mnt/loki/promtail-local-config.yaml.in ]; then
	cp /mnt/loki/promtail-local-config.yaml.in \
	  /usr/local/etc/promtail-local-config.yaml
else
	cp "$TEMPLATEPATH/promtail-local-config.yaml.in" \
	  /usr/local/etc/promtail-local-config.yaml
fi

# correct permissions of existing log files (for upgrading)
mkdir -p /mnt/log/remote/metrics
find /mnt/log/remote -name "*.log" -exec chmod 640 {} \;
find /mnt/log/remote -name "*.log" -exec chgrp promtail {} \;
