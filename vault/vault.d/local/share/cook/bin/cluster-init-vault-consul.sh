#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:"$PATH"

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

# shellcheck disable=SC3013
if [ ! -s /mnt/consulcerts/unwrapped.token ] || \
   [ /mnt/consulcerts/unwrapped.token -ot \
     /mnt/consulcerts/credentials.json ]; then
    WRAPPED_TOKEN=$(< /mnt/consulcerts/credentials.json \
      jq -re .wrapped_token)
    CREDENTIALS_TOKEN=$(< /mnt/consulcerts/credentials.json \
      jq -re .credentials_token)

    umask 177

    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -client-key=/mnt/vaultcerts/agent.key \
      -client-cert=/mnt/vaultcerts/agent.crt \
      -format=json "$WRAPPED_TOKEN" | \
      jq -r '.auth.client_token' > /mnt/consulcerts/unwrapped.token

    DATA=$(
    HOME=/var/empty \
    VAULT_TOKEN="$CREDENTIALS_TOKEN" \
    vault read -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -client-key=/mnt/vaultcerts/agent.key \
      -client-cert=/mnt/vaultcerts/agent.crt \
      -format=json "cubbyhole/consul" |
      jq -e '.data')

    echo "$DATA" | jq -re '.gossip_key' >/mnt/consulcerts/gossip.key
    echo "$DATA" | jq -re '.vault_service_token' \
      >/mnt/consulcerts/vault_service.token
    DNS_TOKEN=$(echo "$DATA" | jq -re '.dns_request_token')
    AGENT_TOKEN=$(echo "$DATA" | jq -re '.agent_token')

    # shellcheck disable=SC3037
    echo -n '{"default":"'"$DNS_TOKEN"'","agent":"'"$AGENT_TOKEN"'"}' \
      >/mnt/consulcerts/acl-tokens.json
fi


GOSSIPKEY="$(cat /mnt/consulcerts/gossip.key)"
TOKEN="$(cat /mnt/consulcerts/unwrapped.token)"
VAULT_SERVICE_TOKEN="$(cat /mnt/consulcerts/vault_service.token)"

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/cluster-consul-agent.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%consulservers%%${sep}$CONSULSERVERS${sep}g" \
  > /usr/local/etc/consul.d/agent.hcl

chown consul /usr/local/etc/consul.d/agent.hcl
chmod 600 /usr/local/etc/consul.d/agent.hcl
echo "s${sep}%%gossipkey%%${sep}$GOSSIPKEY${sep}g" | sed -i '' -f - \
  /usr/local/etc/consul.d/agent.hcl

# place acl-tokens
mkdir -p /var/db/consul
chmod 750 /var/db/consul
cp -a /mnt/consulcerts/acl-tokens.json /var/db/consul/.
chown -R consul:consul /var/db/consul

# Consul-template-consul config
echo "Writing consul-template-consul config"
mkdir -p /usr/local/etc/consul-template-consul.d
cp "$TEMPLATEPATH/cluster-consul-template-consul.hcl.in" \
  /usr/local/etc/consul-template-consul.d/consul-template-consul.hcl
chmod 600 \
  /usr/local/etc/consul-template-consul.d/consul-template-consul.hcl
echo "s${sep}%%token%%${sep}$TOKEN${sep}" | sed -i '' -f - \
  /usr/local/etc/consul-template-consul.d/consul-template-consul.hcl

for name in consul metrics; do
    < "$TEMPLATEPATH/cluster-$name.tpl.in" \
      sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
      sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
      sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" \
      > "/mnt/templates/$name.tpl"
done

mkdir -p /mnt/metricscerts

echo "Enabling and starting consul-template"
sysrc consul_template_consul_syslog_output_enable=YES
service consul-template-consul enable
service consul-template-consul restart || true

timeout --foreground 60 \
  sh -c 'while [ ! -e /mnt/consulcerts/agent.key ]; do sleep 3; done'

# Vault config
echo "s${sep}%%consultoken%%${sep}$VAULT_SERVICE_TOKEN${sep}g" |
  sed -i '' -f - /usr/local/etc/vault.hcl

echo "Start nodemetricsproxy"
timeout --foreground 120 \
  sh -c 'while ! service nginx status nodemetricsproxy; do
    service nginx start nodemetricsproxy || true; sleep 3;
  done'

# configure and (re)start syslog-ng if necessary
"$SCRIPTDIR"/cluster-configure-syslog-ng.sh

service node_exporter restart || true
sleep 2
service consul restart || true
sleep 2
service vault restart || true

sleep 2

# configure unbound to make use of consul
"$SCRIPTDIR"/cluster-setup-local-unbound.sh
