#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

if [ ! -s /mnt/consulcerts/acl-tokens.json ]; then
    umask 177
    < /mnt/consulcerts/credentials.json \
      jq -re .gossip_key >/mnt/consulcerts/gossip.key

    echo "{\"default\": $(< /mnt/consulcerts/credentials.json \
      jq -e .default_consul_token), \"agent\": $(\
      < /mnt/consulcerts/credentials.json \
      jq -e .agent_consul_token)}" >/mnt/consulcerts/acl-tokens.json

    chown consul /mnt/consulcerts/*
fi
