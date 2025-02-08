#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates


# cleanup goaccess
if [ -f /usr/local/etc/goaccess.conf ]; then
    mv -f /usr/local/etc/goaccess.conf /usr/local/etc/goaccess.conf.ignore
fi

# copy in custom goaccess.conf with nginx accesslog hardcoded in
cp -f "$TEMPLATEPATH/goaccess.conf.in" /usr/local/etc/goaccess/goaccess.conf

# this warning pops up for some reason
# /etc/rc: WARNING: $goaccess_enable is not set properly - see rc.conf(5).

# setup service
sysrc goaccess_enable="YES"
sysrc goaccess_config="/usr/local/etc/goaccess/goaccess.conf"
sysrc goaccess_log="/var/log/nginx/access.log"
