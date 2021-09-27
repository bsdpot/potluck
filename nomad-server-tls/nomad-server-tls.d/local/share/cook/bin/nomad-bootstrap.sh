#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
OUTPUT=$("$SCRIPTDIR"/nomad.sh acl bootstrap | grep "Secret ID")
echo "$OUTPUT" | cut -d "=" -f 2 | xargs
