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

# if no replication user exists, create it
if [ "$(echo "SELECT COUNT(*) FROM mysql.user WHERE user = '${REPLICATEUSER}'" | /usr/local/bin/mysql -uroot -p"${DBROOTPASS}" | tail -n1)" -gt 0 ]
then
    echo "Not creating replication user as already exists"
else
    echo "Creating replication user"
    # setup replication user with access from anywhere
    /usr/local/bin/mysql -uroot -p"${DBROOTPASS}" -e "CREATE USER '${REPLICATEUSER}'@'%' IDENTIFIED BY '${REPLICATEPASS}';"
    # and grant required permissions
    /usr/local/bin/mysql -uroot -p"${DBROOTPASS}" -e "GRANT REPLICATION SLAVE ON *.* TO '${REPLICATEUSER}'@'%';"
    # flush perms
    /usr/local/bin/mysql -uroot -p"${DBROOTPASS}" -e "FLUSH PRIVILEGES;"
fi
