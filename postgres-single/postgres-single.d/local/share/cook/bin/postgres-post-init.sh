#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

# we need a path set else sudo not found
export PATH="/usr/local/bin:$PATH"

# make sure we're not in /root else this error occurs:
#
#  could not change directory to "/root": Permission denied
#
cd /tmp || exit 1

# Check if postgres_exporter user exists
USER_EXISTS=$(sudo -u postgres /usr/local/bin/psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='postgres_exporter';")

# If the postgres_exporter user doesn't exist, then create and configure it
if [ -z "$USER_EXISTS" ]; then
    sudo -u postgres psql -c "CREATE USER postgres_exporter with encrypted password '$EXPORTERPASS';"
    sudo -u postgres psql -c "ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;"
    sudo -u postgres psql -c "GRANT CONNECT ON DATABASE postgres TO postgres_exporter;"
    sudo -u postgres psql -c "GRANT pg_monitor to postgres_exporter;"
else
    echo "User postgres_exporter already exists. Not creating."
fi
