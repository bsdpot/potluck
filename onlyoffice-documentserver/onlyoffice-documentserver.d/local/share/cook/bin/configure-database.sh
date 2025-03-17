#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# function to check database exists
check_database() {
    /usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$SETDBPORT/postgres" -lqt | grep -c "$DBNAME"
}

# unset these for dbcheck
set +e
# shellcheck disable=SC3040
set +o pipefail

# check if database exists
dbcheck=$(check_database)

# import database structure if db exists, using greater-than-or-equal-to operator because grep count is 2 if database exists
if [ "$dbcheck" -ge 1 ]; then
    echo "Configuring onlyoffice database"
    /usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$SETDBPORT/$DBNAME" -f /usr/local/www/onlyoffice/documentserver/server/schema/postgresql/createdb.sql
else
    echo "Database $DBNAME does not exist, cannot continue"
    exit 1
fi

# set back after dbcheck
set -e
# shellcheck disable=SC3040
set -o pipefail