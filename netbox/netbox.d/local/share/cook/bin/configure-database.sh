#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH=/usr/local/bin:$PATH

# make sure we're not in /root before running psql commands
cd /tmp

# Check if netbox user exists
USER_EXISTS=$(sudo -u postgres /usr/local/bin/psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='netbox';")

# If the {{ pot_postgresql_nextcloud_user }}  user doesn't exist, create the user with database creation permissions
if [ -z "$USER_EXISTS" ]; then
	sudo -u postgres psql -c "CREATE USER netbox with encrypted password '$DBPASSWORD' CREATEDB;"
	sudo -u postgres psql -c "CREATE DATABASE netbox TEMPLATE template0 ENCODING 'UTF8';"
	sudo -u postgres psql -c "ALTER DATABASE netbox OWNER TO netbox;"
	sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;"
	sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON SCHEMA public TO netbox;"
else
	echo "User netbox already exists."
fi
