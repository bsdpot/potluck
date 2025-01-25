#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

if [ -f /root/config.ldif ]; then
    /usr/local/sbin/slapadd -c -n 0 -F /usr/local/etc/openldap/slapd.d/ -l /root/config.ldif || true
fi

if [ -f /root/data.ldif ]; then
    /usr/local/sbin/slapadd -c -n 1 -F /usr/local/etc/openldap/slapd.d/ -l /root/data.ldif || true
fi
