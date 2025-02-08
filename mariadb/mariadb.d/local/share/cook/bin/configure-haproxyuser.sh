#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
#sep=$'\001'

# This will create a haproxy user for the specified IP passed in
# for the LOADBALANCER parameter.
# There is no password set, but also no access to databases granted.
# This is strictly to allow haproxy mysql-check to function correctly
# from the haproxy-sql pot image.
#
# needs review, allows query for version and server_id from other IPs

echo "Creating haproxy user"
/usr/local/bin/mysql -uroot -p"${DBROOTPASS}" -e "CREATE USER 'haproxy'@'${LOADBALANCER}';"

# flush perms
/usr/local/bin/mysql -uroot -p"${DBROOTPASS}" -e "FLUSH PRIVILEGES;"
