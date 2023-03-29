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

# mkdir directories if not exist
mkdir -p /mnt/opendmarc/

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/opendmarc.conf.in" \
  sed "s${sep}%%mailcertdomain%%${sep}$MAILCERTDOMAIN${sep}g" | \
  sed "s${sep}%%postmasteraddress%%${sep}$POSTMASTERADDRESS${sep}g" \
  > /usr/local/etc/mail/opendmarc.conf

# copy in ignore.hosts, we'll use trusthosts from opendkim, your copied in file must include 127.0.0.0/8 and 10.0.0.0/8
if [ -f /root/dkim_trusted_hosts ]; then
    cp -f /root/dkim_trusted_hosts /mnt/opendmarc/ignore.hosts
else
    echo "127.0.0.0/8" > /mnt/opendmarc/ignore.hosts
    echo "10.0.0.0/8" >> /mnt/opendmarc/ignore.hosts
fi

# enable
service opendmarc enable
