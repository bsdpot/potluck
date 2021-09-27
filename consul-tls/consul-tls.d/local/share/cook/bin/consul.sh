#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e

export PATH=/usr/local/bin:$PATH
export CONSUL_HTTP_ADDR=${CONSUL_HTTP_ADDR:-127.0.0.1:8500}
export CONSUL_HTTP_SSL=true
export CONSUL_CLIENT_CERT=/mnt/consulcerts/agent.crt
export CONSUL_CLIENT_KEY=/mnt/consulcerts/agent.key
export CONSUL_CACERT=/mnt/consulcerts/ca_chain.crt
export CONSUL_TLS_SERVER_NAME="server.$DATACENTER.consul"
consul "$@"
