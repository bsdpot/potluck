#!/bin/sh

TOKEN_POLICIES="$1"
TOKEN_DESCRIPTION="$2"

if [ -z "$TOKEN_POLICIES" ] || [ -z "$TOKEN_DESCRIPTION" ]; then
    2>&1 echo "Usage: $0 policies description"
    exit 1
fi


TOKEN_POLICIES_PARAMS=""
for policy in $(echo "$TOKEN_POLICIES" | tr ',' ' '); do
    TOKEN_POLICIES_PARAMS="$TOKEN_POLICIES_PARAMS -policy-name $policy"
done


set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC2086
"$SCRIPTDIR"/consul.sh acl token create \
  -description "$TOKEN_DESCRIPTION" \
  $TOKEN_POLICIES_PARAMS  -format json | jq -r ".SecretID"
