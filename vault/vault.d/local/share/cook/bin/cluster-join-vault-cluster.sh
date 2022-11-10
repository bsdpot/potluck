#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

LEADER_IP="$1"

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

WRAPPED_TOKEN=$(< /mnt/vaultcerts/credentials.json \
  jq -re .wrapped_token)
< /mnt/vaultcerts/credentials.json \
  jq -re .cert >/mnt/vaultcerts/agent.crt
< /mnt/vaultcerts/credentials.json \
  jq -re .ca >>/mnt/vaultcerts/agent.crt
< /mnt/vaultcerts/credentials.json \
  jq -re .ca_root >/mnt/vaultcerts/ca_root.crt
(
    umask 177
    < /mnt/vaultcerts/credentials.json \
      jq -re .key >/mnt/vaultcerts/agent.key
)

chown vault /mnt/vaultcerts/agent.crt
chown vault /mnt/vaultcerts/agent.key

"$SCRIPTDIR"/cluster-enable-vault-tls.sh

"$SCRIPTDIR"/cluster-setup-local-unbound-static.sh "$LEADER_IP"

timeout --foreground 120 \
  sh -c 'while ! host -ta active.vault.service.consul |
    grep -F -- "'"$LEADER_IP"'"; do sleep 1; done'


sleep 5

LOCAL_VAULT="https://127.0.0.1:8200"

if ! service nginx onestatus vaultproxy; then
    echo "Starting vaultproxy"
    service nginx start vaultproxy
    sleep 1
fi

vault \
  operator raft join \
  -address="$LOCAL_VAULT" \
  -ca-cert=/mnt/vaultcerts/ca_root.crt \
  -leader-client-key=@/mnt/vaultcerts/agent.key \
  -leader-client-cert=@/mnt/vaultcerts/agent.crt \
  -leader-ca-cert=@/mnt/vaultcerts/ca_root.crt \
  -tls-server-name=active.vault.service.consul \
  -retry "https://$LEADER_IP:8200"

echo "Wait for local vault..."
for i in $(jot 30); do
    echo "attempt: $i"
    RAFT_JSON=$(vault status \
      -address="$LOCAL_VAULT" \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -format=json || true)
    RAFT_COMMITTED=$(echo "$RAFT_JSON" | jq -r ".raft_committed_index")
    RAFT_APPLIED=$(echo "$RAFT_JSON" | jq -r ".raft_applied_index")
    case "$RAFT_COMMITTED" in
      ""|*[!0-9]*) ;;
      *) [ "$RAFT_COMMITTED" = "$RAFT_APPLIED" ] && break ;;
    esac
    sleep 2
done


if ! service consul-template onestatus; then
    echo "Unwrapping local consul-template token"
    CLUSTER_PKI_TOKEN_JSON=$(
      HOME=/var/empty \
      vault unwrap \
        -address="https://$LEADER_IP:8200" \
        -tls-server-name=active.vault.service.consul \
        -ca-cert=/mnt/vaultcerts/ca_root.crt \
        -client-key=/mnt/vaultcerts/agent.key \
        -client-cert=/mnt/vaultcerts/agent.crt \
        -format=json "$WRAPPED_TOKEN")
    CLUSTER_PKI_TOKEN=$(echo "$CLUSTER_PKI_TOKEN_JSON" |\
      jq -r ".auth.client_token")

    echo "Writing consul-template config"
    mkdir -p /usr/local/etc/consul-template.d

    # shellcheck disable=SC3003
    # safe(r) separator for sed
    sep=$'\001'

    cp "$TEMPLATEPATH/cluster-consul-template.hcl.in" \
      /usr/local/etc/consul-template.d/consul-template.hcl
    chmod 600 \
      /usr/local/etc/consul-template.d/consul-template.hcl
    echo "s${sep}%%token%%${sep}$CLUSTER_PKI_TOKEN${sep}" | sed -i '' -f - \
      /usr/local/etc/consul-template.d/consul-template.hcl

    < "$TEMPLATEPATH/cluster-vault.tpl.in" \
      sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
      sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" \
      > "/mnt/templates/cluster-vault.tpl"

    echo "Enabling and starting consul-template"
    sysrc consul_template_syslog_output_enable=YES
    service consul-template enable
    service consul-template start
fi
