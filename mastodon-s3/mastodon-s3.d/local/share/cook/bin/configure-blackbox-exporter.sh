#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/blackbox_exporter.yml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/blackbox_exporter.yml

# set RC settings and enable blackbox_exporter
# needs to run as root for icmp
sysrc blackbox_exporter_user=root
sysrc blackbox_exporter_config="/usr/local/etc/blackbox_exporter.yml"
echo "blackbox_exporter_listen_address=\"$IP:9115\"" >> /etc/rc.conf
service blackbox_exporter enable || true
