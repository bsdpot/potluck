#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name operator-ui ||
  "$SCRIPTDIR"/consul.sh acl policy create -name operator-ui \
    -rules 'service_prefix "" {
  policy = "read"
}
key_prefix "" {
  policy = "read"
}
node_prefix "" {
  policy = "read"
}
'
