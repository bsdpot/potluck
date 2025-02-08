#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# create credentials directory
mkdir -p /root/.aws

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# removed as not using auth
# copy in credentials file
#< "$TEMPLATEPATH/credentials.in" \
#  sed "s${sep}%%username%%${sep}$USERNAME${sep}g" | \
#  sed "s${sep}%%password%%${sep}$PASSWORD${sep}g" \
#  > /root/.aws/credentials
