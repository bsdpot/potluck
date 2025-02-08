#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# if nginx.conf copied in
if [ -f /root/nginx.conf ]; then
    cp -f /root/nginx.conf /usr/local/etc/nginx/nginx.conf
    service nginx enable || true
    service nginx start || true
else
    echo "There is no /root/nginx.conf file"
fi
