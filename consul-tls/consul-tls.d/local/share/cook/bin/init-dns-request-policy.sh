#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name dns-request ||
  "$SCRIPTDIR"/consul.sh acl policy create -name dns-request \
    -rules 'node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
service "node-exporter" {
  policy = "write"
}
'

# XXX: Make node-exporter a separate policy

TOKEN=$("$SCRIPTDIR"/issue-dns-request-token.sh "$NODENAME")

"$SCRIPTDIR"/consul.sh acl set-agent-token default "$TOKEN"
