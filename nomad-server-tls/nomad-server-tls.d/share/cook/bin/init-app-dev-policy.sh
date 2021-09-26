#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/nomad.sh acl policy info app-dev ||
  "$SCRIPTDIR"/nomad.sh acl policy apply \
    -description "Application Developer policy" app-dev \
    "$TEMPLATEPATH/nomad-app-dev-policy.hcl.in"
