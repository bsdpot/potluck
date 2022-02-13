#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name consul-metrics ||
  "$SCRIPTDIR"/consul.sh acl policy create -name consul-metrics \
    -rules 'agent_prefix "consul-node" {
  policy = "read"
}
'
