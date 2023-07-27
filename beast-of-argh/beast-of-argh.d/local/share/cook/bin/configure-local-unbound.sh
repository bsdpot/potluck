#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

echo 'server:
  do-not-query-localhost: no
  domain-insecure: "consul"

#Add consul as a stub-zone
stub-zone:
  name: "consul"
  stub-addr: 127.0.0.1@8600
' >/etc/unbound/conf.d/consul.conf

echo 'server:
  username: unbound
  directory: /var/unbound
  chroot: /var/unbound
  pidfile: /var/run/local_unbound.pid
  auto-trust-anchor-file: /var/unbound/root.key
  interface: 0.0.0.0
  access-control: 10.0.0.0/8 allow
  access-control: 127.0.0.0/8 allow

include: /var/unbound/lan-zones.conf
include: /var/unbound/control.conf
include: /var/unbound/conf.d/*.conf
' >/etc/unbound/unbound.conf

service local_unbound enable || true
sysrc local_unbound_forwarders="${DNSFORWARDERS:-none}" || true
service local_unbound setup || true
service local_unbound restart || true
