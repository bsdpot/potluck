#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# setup directories for loki
mkdir -p /mnt/loki/rules-temp

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# loki setup
# download the source files
fetch https://github.com/grafana/loki/releases/download/\
v2.2.1/loki-freebsd-amd64.zip --output=/root/loki-freebsd-amd64.zip

# extract loki and copy to /usr/local/bin
cd /root/
if [ -f /root/loki-freebsd-amd64.zip ]; then
   unzip loki-freebsd-amd64.zip
   if [ -f /root/loki-freebsd-amd64 ]; then
       cp -f /root/loki-freebsd-amd64 /usr/local/bin/loki-freebsd-amd64
       chmod a+x /usr/local/bin/loki-freebsd-amd64
       ln -s /usr/local/bin/loki-freebsd-amd64 /usr/local/bin/loki
       rm -rf /root/loki-freebsd-amd64
       rm -rf /root/loki-freebsd-amd64.zip
   fi
fi

# copy in loki rc
cp "$TEMPLATEPATH/loki.rc.in" /usr/local/etc/rc.d/loki
chmod +x /usr/local/etc/rc.d/loki
service loki enable
sysrc loki_syslog_output_enable="YES"

# copy in loki config file
< "$TEMPLATEPATH/loki-local-config.yaml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/loki-local-config.yaml

# chown to loki user
chown -R loki:loki /mnt/loki

# promtail
# download the source files
fetch https://github.com/grafana/loki/releases/download/\
v2.2.1/promtail-freebsd-amd64.zip --output=/root/promtail-freebsd-amd64.zip

# extract promtail and copy to /usr/local/bin
if [ -f /root/promtail-freebsd-amd64.zip ]; then
    unzip promtail-freebsd-amd64.zip
    if [ -f /root/promtail-freebsd-amd64 ]; then
        cp -f /root/promtail-freebsd-amd64 \
          /usr/local/bin/promtail-freebsd-amd64
        chmod a+x /usr/local/bin/promtail-freebsd-amd64
        ln -s /usr/local/bin/promtail-freebsd-amd64 /usr/local/bin/promtail
        rm -rf /root/promtail-freebsd-amd64
        rm -rf /root/promtail-freebsd-amd64.zip
    fi
fi

# copy in the promtail rc file
cp "$TEMPLATEPATH/promtail.rc.in" /usr/local/etc/rc.d/promtail
chmod +x /usr/local/etc/rc.d/promtail
service promtail enable
sysrc promtail_syslog_output_enable="YES"

# copy in the promtail config file
< "$TEMPLATEPATH/promtail-local-config.yaml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/promtail-local-config.yaml
