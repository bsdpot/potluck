#!/bin/sh

if [ $# -ne 1 ]; then
  2>&1 echo "Usage $0 vault_ip"
  exit 1
fi

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

echo "server:
        local-zone: active.vault.service.consul typetransparent
        local-data: \"active.vault.service.consul A $1\"
" >/etc/unbound/conf.d/vault-static.conf

rm -f /etc/unbound/conf.d/consul.conf

service local_unbound enable || true
sysrc local_unbound_forwarders=none || true
service local_unbound restart || true
