#!/bin/sh

set -e

echo 'server:
  do-not-query-localhost: no
  domain-insecure: "consul"

#Add consul as a stub-zone
stub-zone:
  name: "consul"
  stub-addr: 127.0.0.1@8600
' >/etc/unbound/conf.d/consul.conf

service local_unbound enable || true
sysrc local_unbound_forwarders=none || true
service local_unbound restart || true
