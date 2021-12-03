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

WRAPPED_TOKEN=$(< /mnt/certs/credentials.json \
  jq -re .wrapped_token)
< /mnt/certs/credentials.json \
  jq -re .cert >/mnt/certs/agent.crt
< /mnt/certs/credentials.json \
  jq -re .ca >/mnt/certs/ca.crt
< /mnt/certs/credentials.json \
  jq -re .ca_chain >/mnt/certs/ca_chain.crt
< /mnt/certs/credentials.json \
  jq -re .ca_root >>/mnt/certs/ca_chain.crt
< /mnt/certs/credentials.json \
  jq -re .ca_root >/mnt/certs/ca_root.crt
(
    umask 177
    < /mnt/certs/credentials.json \
      jq -re .key >/mnt/certs/agent.key
)

"$SCRIPTDIR"/cluster-enable-vault-tls.sh

echo "$LEADER_IP active.vault.service.consul" >>/etc/hosts

"$SCRIPTDIR"/cluster-vault.sh \
  operator raft join \
  -leader-client-key=@/mnt/certs/agent.key \
  -leader-client-cert=@/mnt/certs/agent.crt \
  -leader-ca-cert=@/mnt/certs/ca_chain.crt \
  -tls-server-name=active.vault.service.consul \
  -retry "https://$LEADER_IP:8200"

echo "Wait for local vault..."
for i in $(jot 30); do
    echo "attempt: $i"
    RAFT_JSON=$(vault status \
      -address="$LOCAL_VAULT" \
      -ca-cert=/mnt/certs/ca_chain.crt \
       -format=json || true)
    RAFT_COMMITTED=$(echo "$RAFT_JSON" | jq -r ".raft_committed_index")
    RAFT_APPLIED=$(echo "$RAFT_JSON" | jq -r ".raft_applied_index")
    case "$RAFT_COMMITTED" in
      ""|*[!0-9]*) ;;
      *) [ "$RAFT_COMMITTED" = "$RAFT_APPLIED" ] && break ;;
    esac
    sleep 2
done

if ! service vault-agent onestatus; then
    echo "Starting vault-agent"
    service vault-agent start
fi

if ! service consul-template onestatus; then
    echo "Unwrapping local consul-template token"
    CLUSTER_PKI_TOKEN_JSON=$(
      HOME=/var/empty \
      vault unwrap \
        -address="https://$LEADER_IP:8200" \
        -tls-server-name=active.vault.service.consul \
        -ca-cert=/mnt/certs/ca_chain.crt \
        -client-key=/mnt/certs/agent.key \
        -client-cert=/mnt/certs/agent.crt \
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

    for name in cluster-agent.crt cluster-agent.key cluster-ca.crt; do
        < "$TEMPLATEPATH/$name.tpl.in" \
          sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
          sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
          sed "s${sep}%%attl%%${sep}$ATTL${sep}g" | \
          sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
          > "/mnt/templates/$name.tpl"
    done

    echo "Enabling and starting consul-template"
    sysrc consul_template_syslog_output_enable=YES
    service consul-template enable
    service consul-template start
fi
