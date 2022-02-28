#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name "$NODENAME" ||
  "$SCRIPTDIR"/consul.sh acl policy create -name "$NODENAME" \
    -rules 'node "'"$NODENAME"'" {
  policy = "write"
}
'

TOKEN=$("$SCRIPTDIR"/consul.sh acl token create \
  -description "$NODENAME agent token" \
  -policy-name "$NODENAME" -format json | jq -r ".SecretID")

"$SCRIPTDIR"/consul.sh acl set-agent-token agent "$TOKEN"
