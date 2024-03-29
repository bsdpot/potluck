#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# setup directories for loki
mkdir -p /mnt/loki/rules-temp
mkdir -p /tmp/loki

# loki setup

# create loki user
/usr/sbin/pw useradd -n loki -c 'loki user' -m -s /usr/sbin/nologin -h -

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in loki rc
cp -f "$TEMPLATEPATH/loki.rc.in" /usr/local/etc/rc.d/loki
chmod +x /usr/local/etc/rc.d/loki
service loki enable || true
sysrc loki_syslog_output_enable="YES" || true
# not specifically needed if permissions on /tmp/loki and loki-local-config.yaml
# are correct
#sysrc loki_user="loki"
#sysrc loki_group="loki"
#sysrc loki_config="/usr/local/etc/loki-local-config.yaml"

# copy in loki config file, make sure loki can RW it
< "$TEMPLATEPATH/loki-local-config.yaml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/loki-local-config.yaml

# set permissions on directories and files
chown loki:loki /usr/local/etc/loki-local-config.yaml
chown -R loki:loki /mnt/loki
chown -R loki:loki /tmp/loki

# promtail setup

# copy in the promtail rc file
cp "$TEMPLATEPATH/promtail.rc.in" /usr/local/etc/rc.d/promtail
chmod +x /usr/local/etc/rc.d/promtail
service promtail enable || true
sysrc promtail_syslog_output_enable="YES" || true

# copy in the promtail config file
< "$TEMPLATEPATH/promtail-local-config.yaml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/promtail-local-config.yaml
