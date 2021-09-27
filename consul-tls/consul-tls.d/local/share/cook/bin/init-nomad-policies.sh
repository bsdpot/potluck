#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name nomad-server ||
  "$SCRIPTDIR"/consul.sh acl policy create -name nomad-server \
    -rules 'agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}

acl = "write"
'

"$SCRIPTDIR"/consul.sh acl policy read -name nomad-client ||
  "$SCRIPTDIR"/consul.sh acl policy create -name nomad-client \
    -rules 'agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}
'
