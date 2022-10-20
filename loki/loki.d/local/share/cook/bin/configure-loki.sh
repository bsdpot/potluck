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

# copy in loki rc
cp "$TEMPLATEPATH/loki.rc.in" /usr/local/etc/rc.d/loki
chmod +x /usr/local/etc/rc.d/loki
service loki enable
sysrc loki_syslog_output_enable="YES"

# copy in loki config file
if [ -f /mnt/loki/loki-local-config.yaml.in ]; then
	cp /mnt/loki/loki-local-config.yaml.in \
	  /usr/local/etc/loki-local-config.yaml
else
	cp "$TEMPLATEPATH/loki-local-config.yaml.in" \
	  /usr/local/etc/loki-local-config.yaml
fi

# create loki user
/usr/sbin/pw useradd -n loki -c 'loki user' -m \
  -s /usr/bin/nologin -h -

# chown to loki user
chown -R loki:loki /mnt/loki

# promtail setup

# copy in the promtail rc file
cp "$TEMPLATEPATH/promtail.rc.in" /usr/local/etc/rc.d/promtail
chmod +x /usr/local/etc/rc.d/promtail
service promtail enable
sysrc promtail_syslog_output_enable="YES"

# copy in the promtail config file
if [ -f /mnt/loki/promtail-local-config.yaml.in ]; then
	cp /mnt/loki/promtail-local-config.yaml.in \
	  /usr/local/etc/promtail-local-config.yaml
else
	cp "$TEMPLATEPATH/promtail-local-config.yaml.in" \
	  /usr/local/etc/promtail-local-config.yaml
fi
