#!/bin/sh
/usr/local/bin/curl -s \
 --cacert /mnt/postgrescerts/ca_chain.crt \
 --cert /mnt/postgrescerts/client.crt \
 --key /mnt/postgrescerts/client.key \
 https://127.0.0.1:8008/cluster | /usr/local/bin/jq .
