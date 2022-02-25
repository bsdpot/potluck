#!/bin/sh

## shellcheck disable=SC1091
#. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH="$SCRIPTDIR/../templates"
CONFIG_TMPL="/mnt/haproxy.conf.default.in"

mkdir -p /usr/local/etc/haproxy/certs
mkdir -p /var/run/haproxy

(
  timeout --foreground 60 \
    sh -c 'while [ ! -e /mnt/servicecerts/client.crt ]; do sleep 3; done'

  umask 177

#  cat /mnt/servicecerts/client.crt \
#    /mnt/servicecerts/client.key \
#    /mnt/servicecerts/ca_chain.crt \
#    >/usr/local/etc/haproxy/certs/serviceclient.pem
#  cp /mnt/servicecerts/ca_chain.crt \
#    /usr/local/etc/haproxy/certs/service-ca.pem

  #CERT_DIR="/usr/local/etc/dehydrated/certs/$PUBLIC_NAME"
  #if [ -L "$CERT_DIR/privkey.pem" ] && [ -L "$CERT_DIR/fullchain.pem" ]; then
  #    cat "$CERT_DIR/privkey.pem" "$CERT_DIR/fullchain.pem" \
  #      >/mnt/haproxycerts/compute.pem
  #fi
)

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

[ -e "$CONFIG_TMPL" ] || CONFIG_TMPL="$TEMPLATEPATH/haproxy.conf.in"

< "$CONFIG_TMPL" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/haproxy/haproxy.conf

# enable haproxy
service haproxy enable
sysrc haproxy_config=/usr/local/etc/haproxy/haproxy.conf

#if [ -f /mnt/haproxycerts/compute.pem ]; then
#    service haproxy restart || true
#fi
