#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# configure self-signed certificates by adding minio certicate to local CA store
echo "" |/usr/bin/openssl s_client -showcerts -noservername -connect "$SERVERONE" |/usr/bin/openssl x509 -outform PEM > /tmp/cert.pem
if [ -f /tmp/cert.pem ]; then
    cat /tmp/cert.pem >> /usr/local/share/certs/ca-root-nss.crt
fi
