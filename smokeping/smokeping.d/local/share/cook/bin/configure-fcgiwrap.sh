#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

sysrc fcgiwrap_socket_owner="www"

# -f means redirect errors to web server logs
# -c 2 means prefork 2 fcgiwrap processes
sysrc fcgiwrap_flags="-f -c 2"

# enable
service fcgiwrap enable
