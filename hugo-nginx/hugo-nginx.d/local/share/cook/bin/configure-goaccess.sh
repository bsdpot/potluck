#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# make directory
mkdir -p /usr/local/etc/goaccess

# copy in custom goaccess.conf with nginx accesslog hardcoded in
cp -f "$TEMPLATEPATH/goaccess.conf.in" /usr/local/etc/goaccess/goaccess.conf

# move old goaccess config
if [ -f /usr/local/etc/goaccess.conf ]; then
    mv -f /usr/local/etc/goaccess.conf /usr/local/etc/goaccess.conf.ignore
fi

# setup service
sysrc goaccess_config="/usr/local/etc/goaccess/goaccess.conf"
sysrc goaccess_log="/var/log/nginx/access.log"
service goaccess enable || true
