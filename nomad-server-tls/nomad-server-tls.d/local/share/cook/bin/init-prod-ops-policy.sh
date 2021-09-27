#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/nomad.sh acl policy info prod-ops ||
  "$SCRIPTDIR"/nomad.sh acl policy apply \
    -description "Production Operations policy" prod-ops \
    "$TEMPLATEPATH/nomad-prod-ops-policy.hcl.in"
