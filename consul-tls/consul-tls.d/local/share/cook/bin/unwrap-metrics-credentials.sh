#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

if [ ! -s /mnt/metricscerts/unwrapped.token ]; then
    TOKEN=$(< /mnt/metricscerts/credentials.json \
      jq -re .wrapped_token)
    < /mnt/metricscerts/credentials.json \
      jq -re .cert >/mnt/metricscerts/metrics.crt
    < /mnt/metricscerts/credentials.json \
      jq -re .ca >/mnt/metricscerts/metricsca.crt
    < /mnt/metricscerts/credentials.json \
      jq -re .ca_chain >/mnt/metricscerts/ca_chain.crt
    < /mnt/metricscerts/credentials.json \
      jq -re .ca_root >>/mnt/metricscerts/ca_chain.crt
    < /mnt/metricscerts/credentials.json \
      jq -re .ca_root >/mnt/metricscerts/ca_root.crt
    umask 177
    < /mnt/metricscerts/credentials.json \
      jq -re .key >/mnt/metricscerts/metrics.key
    < /mnt/metricscerts/credentials.json \
      jq -re .gossip_key >/mnt/metricscerts/gossip.key
    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/certs/ca_chain.crt \
      -client-key=/mnt/certs/client.key \
      -client-cert=/mnt/certs/client.crt \
      -format=json "$TOKEN" | \
      jq -r '.auth.client_token' > /mnt/metricscerts/unwrapped.token
    chown nodeexport /mnt/metricscerts/*
fi
