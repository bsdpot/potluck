#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e

export PATH=/usr/local/bin:$PATH
export NOMAD_ADDR=${NOMAD_ADDR:-https://127.0.0.1:4646}
export NOMAD_CLIENT_CERT=/mnt/nomadcerts/agent.crt
export NOMAD_CLIENT_KEY=/mnt/nomadcerts/agent.key
export NOMAD_CACERT=/mnt/nomadcerts/ca_root.crt
export NOMAD_TLS_SERVER_NAME="server.global.nomad"
nomad "$@"
