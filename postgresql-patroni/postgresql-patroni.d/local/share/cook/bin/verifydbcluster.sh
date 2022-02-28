#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

curl -sfS \
 --cacert /mnt/consulcerts/ca_root.crt \
 --cert /mnt/consulcerts/agent.crt \
 --key /mnt/consulcerts/agent.key \
 "https://$IP:8008/cluster" | jq "."
