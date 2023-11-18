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

# perform operator init on unsealed node and get recovery keys instead of
# unseal keys, save to file - might be moved out of this later
if [ -s "/root/recovery.keys" ]; then
  echo "Skipping vault init (recovery keys exist)"
else
  echo "Initializing vault node"
  (
      umask 177
      vault operator init -address="$LOCAL_VAULT" \
        -format=json > /root/recovery.keys
  )
fi

ROOTKEY=$(< /root/recovery.keys jq -r ".root_token")

if [ -z "$ROOTKEY" ]; then
    echo "Something went wrong with recovery keys, sorry"
    exit 1
fi

# The vault documentation says this is not done on first node, but raft
# only works if it is!
#echo "Joining the raft cluster"
#vault operator raft join -address="$LOCAL_VAULT"

echo "Logging in to local vault instance"
for i in $(jot 30); do
    echo "login attempt: $i"
    (
        umask 177
        echo "$ROOTKEY" | vault login \
          -address="$LOCAL_VAULT" -method=token -field=token \
          token=- > /dev/null
    ) && break
    sleep 2
done

if [ ! -s /root/.vault-token ]; then
    echo "Login to local vault instance failed, giving up"
    exit 1
fi

# setup logging
echo "enabling /mnt/vault/audit.log"
vault audit enable -address="$LOCAL_VAULT" \
  file file_path=/mnt/vault/audit.log

# XXX: Maybe do this later?
echo "tuning cluster"
vault operator raft autopilot set-config \
  -address="$LOCAL_VAULT" -dead-server-last-contact-threshold=24h \
  -server-stabilization-time=30s -cleanup-dead-servers=true \
  -min-quorum=3

echo "Setup up vault cluster pki"
"$SCRIPTDIR"/cluster-setup-vault-pki.sh

LOCAL_VAULT="https://127.0.0.1:8200"

echo "Wait for local vault..."
for i in $(jot 10); do
    echo "attempt: $i"
    LEADER_ADDRESS=$(vault status \
      -address="$LOCAL_VAULT" \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
       -format=json | jq -r ".leader_address" || true)
    [ "$LEADER_ADDRESS" = "https://$IP:8200" ] && break
    sleep 2
done

if ! service nginx onestatus vaultproxy; then
    echo "Starting vaultproxy"
    service nginx start vaultproxy
fi

if ! service consul-template onestatus; then
    "$SCRIPTDIR"/cluster-configure-consul-template.sh

    echo "Starting consul-template"
    service consul-template start
fi

echo "Reload vault"
service vault reload
