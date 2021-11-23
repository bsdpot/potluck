#!/bin/sh

POLICYNAME="$1"
NODENAME="$2"

if [ -z "$POLICYNAME" ] || [ -z "$NODENAME" ]; then
    2>&1 echo "Usage: $0 policyname nodename"
    exit 1
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

"$SCRIPTDIR"/consul.sh acl policy read -name "$POLICYNAME" ||
  "$SCRIPTDIR"/consul.sh acl policy create -name "$POLICYNAME" \
    -rules "node \"$NODENAME\" { policy = \"write\" }"
