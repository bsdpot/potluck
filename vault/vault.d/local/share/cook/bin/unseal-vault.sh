#!/bin/sh
set -e
export PATH=/usr/local/bin:"$PATH"
if echo | openssl s_client -connect 127.0.0.1:8200 >/dev/null 2>&1
then
    export VAULT_ADDR=https://127.0.0.1:8200
    export VAULT_CACERT=/mnt/unsealcerts/ca_root.crt
else
    export VAULT_ADDR=http://127.0.0.1:8200
fi
vault "$@"
