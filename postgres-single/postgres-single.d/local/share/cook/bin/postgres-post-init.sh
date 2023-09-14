#!/bin/sh

# create postgres_exporter user
echo "\
ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;

GRANT CONNECT ON DATABASE postgres TO postgres_exporter;
GRANT pg_monitor to postgres_exporter;\
" | PGOPTIONS="-c synchronous_commit=local" /usr/local/bin/psql -Xd "$2"
