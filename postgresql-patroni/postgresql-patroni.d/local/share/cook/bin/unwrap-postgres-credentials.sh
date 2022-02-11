#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

if [ ! -s /mnt/postgrescerts/unwrapped.token ]; then
    #WRAPPED_TOKEN=$(< /mnt/postgrescerts/credentials.json \
    #  jq -re .wrapped_token)
    < /mnt/postgrescerts/credentials.json \
      jq -re .cert >/mnt/postgrescerts/postgresserver.crt
    < /mnt/postgrescerts/credentials.json \
      jq -re .ca >/mnt/postgrescerts/postgresca.crt
    < /mnt/postgrescerts/credentials.json \
      jq -re .ca_chain >/mnt/postgrescerts/ca_chain.crt
    < /mnt/postgrescerts/credentials.json \
      jq -re .ca_root >>/mnt/postgrescerts/ca_chain.crt
    < /mnt/postgrescerts/credentials.json \
      jq -re .ca_root >/mnt/postgrescerts/ca_root.crt
    umask 177
    < /mnt/postgrescerts/credentials.json \
      jq -re .key >/mnt/postgrescerts/postgresserver.key
#    < /mnt/postgrescerts/credentials.json \
#      jq -re .gossip_key >/mnt/postgrescerts/gossip.key
    < /mnt/postgrescerts/credentials.json \
      jq -re .postgres_service_token >/mnt/postgrescerts/postgres_service.token

    < /mnt/postgrescerts/credentials.json \
      jq -re .admin_key >/mnt/postgrescerts/admin.pass
    < /mnt/postgrescerts/credentials.json \
      jq -re .exporter_key >/mnt/postgrescerts/exporter.pass
    < /mnt/postgrescerts/credentials.json \
      jq -re .replicator_key >/mnt/postgrescerts/replicator.pass
    < /mnt/postgrescerts/credentials.json \
      jq -re .superuser_key >/mnt/postgrescerts/superuser.pass

 #   HOME=/var/empty \
 #   vault unwrap -address="https://active.vault.service.consul:8200" \
 #     -tls-server-name=active.vault.service.consul \
 #     -ca-cert=/mnt/certs/ca_chain.crt \
 #     -client-key=/mnt/certs/client.key \
 #     -client-cert=/mnt/certs/client.crt \
 #     -format=json "$WRAPPED_TOKEN" | \
 #     jq -r '.auth.client_token' > /mnt/postgrescerts/unwrapped.token
    chown postgres /mnt/postgrescerts/*
fi
