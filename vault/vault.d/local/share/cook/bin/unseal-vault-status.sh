#!/bin/sh
set -e
SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
"$SCRIPTDIR"/unseal-vault.sh status
