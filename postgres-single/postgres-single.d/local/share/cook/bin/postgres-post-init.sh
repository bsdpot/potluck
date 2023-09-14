#!/bin/sh

# create postgres_exporter user
sudo -u postgres /usr/local/bin/psql -c "CREATE USER postgres_exporter;" || true
sudo -u postgres /usr/local/bin/psql -c "ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;"
sudo -u postgres /usr/local/bin/psql -c "GRANT CONNECT ON DATABASE postgres TO postgres_exporter;"
sudo -u postgres /usr/local/bin/psql -c "GRANT pg_monitor to postgres_exporter;"
