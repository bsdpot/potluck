#!/bin/sh
/usr/local/bin/curl -s \
 --cacert /mnt/postgrescerts/ca_chain.crt \
 --cert /mnt/postgrescerts/agent.crt \
 --key /mnt/postgrescerts/agent.key \
 https://127.0.0.1:8008/cluster | /usr/local/bin/jq .
