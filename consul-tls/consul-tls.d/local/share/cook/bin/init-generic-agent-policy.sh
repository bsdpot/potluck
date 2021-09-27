#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name "$1" ||
  "$SCRIPTDIR"/consul.sh acl policy create -name "$1" \
    -rules "node \"$1\" { policy = \"write\" }"
