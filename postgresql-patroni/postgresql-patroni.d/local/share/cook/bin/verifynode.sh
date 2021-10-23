#!/bin/sh
/usr/local/bin/curl -s \
 --cacert /mnt/postgrescerts/ca_chain.crt \
 --cert /mnt/postgrescerts/postgres.crt \
 --key /mnt/postgrescerts/postgres.key \
 https://127.0.0.1:8008/patroni | /usr/local/bin/jq .