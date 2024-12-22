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

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# setup the netbox gunicorn template
cp -f "$TEMPLATEPATH/netbox.conf.py.in" /usr/local/etc/netbox.conf.py

# enable nginx
service gunicorn enable

# start gunicorn
service gunicorn start



