#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")

LOCAL_VAULT="http://127.0.0.1:8200"

echo "Set up local_unbound using static vault ip"
"$SCRIPTDIR"/cluster-setup-local-unbound-static.sh "$IP"

echo "Wait for local_unbound resolving to leader IP"
timeout --foreground 120 \
  sh -c 'while ! host -ta active.vault.service.consul |
    grep -F -- "'"$IP"'"; do sleep 1; done'

echo "Set vault-recovery.hcl as config"
#Disables tls and tcp listener
sysrc vault_config=/usr/local/etc/vault-recover.hcl

echo "Add peers.json"
cat > /mnt/vault/raft/peers.json << EOF
[
  {
    "id": "$NODENAME",
    "address": "$IP:8201",
    "non_voter": false
  }
]
EOF

echo "Restarting vault service"
service vault stop || true
timeout --foreground 120 \
  sh -c 'while ! service vault status; do
    service vault start || true; sleep 5;
  done'

echo "Wait for vault leader to become available"
# shellcheck disable=SC2016
timeout --foreground 120 \
  sh -c 'while [ "$(
    VAULT_ADDR='"$LOCAL_VAULT"' vault status --format=json |
      jq -r .leader_address)" != "'$LOCAL_VAULT'" ]; do sleep 1; done'

echo "Reconfigure vault pki"
"$SCRIPTDIR"/cluster-setup-vault-pki.sh

LOCAL_VAULT="https://127.0.0.1:8200"

echo "Restarting vault proxy"
service nginx restart vaultproxy

echo "Wait for vault leader to become available using TLS"
# shellcheck disable=SC2016
timeout --foreground 120 \
  sh -c 'while [ "$(
    VAULT_ADDR='"$LOCAL_VAULT"' vault status --format=json \
      -ca-cert=/mnt/vaultcerts/ca_root.crt |
      jq -r .leader_address)" != "https://'"$IP"':8200" ]; do sleep 1; done'

echo "Configure and re-start consul-template"
"$SCRIPTDIR"/cluster-configure-consul-template.sh
service consul-template restart || true
