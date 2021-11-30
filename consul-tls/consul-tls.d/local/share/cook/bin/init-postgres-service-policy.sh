#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name postgres-service ||
  "$SCRIPTDIR"/consul.sh acl policy create -name postgres-service \
    -rules 'service_prefix "postgresql" {
  policy = "write"
}
key_prefix "service/postgresql" {
  policy = "write"
}
session_prefix "" {
  policy = "write"
}
'
