#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name vault-service ||
  "$SCRIPTDIR"/consul.sh acl policy create -name vault-service \
    -rules '{
  "key_prefix": {
    "vault/": {
      "policy": "write"
    }
  },
  "node_prefix": {
    "": {
      "policy": "write"
    }
  },
  "service": {
    "vault": {
      "policy": "write"
    }
  },
  "agent_prefix": {
    "": {
      "policy": "write"
    }
  },
  "session_prefix": {
    "": {
      "policy": "write"
    }
  }
}
'
