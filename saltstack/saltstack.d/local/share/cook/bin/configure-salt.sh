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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/master.cfg.in" \
  sed "s${sep}%%pkipath%%${sep}$PKIPATH${sep}g" | \
  sed "s${sep}%%statepath%%${sep}$STATEPATH${sep}g" | \
  sed "s${sep}%%pillarpath%%${sep}$PILLARPATH${sep}g" \
  > /usr/local/etc/salt/master

# copy over keys if they've been copied in
if [ -f /root/master.pem ]; then
    # backup existing key and set destination to readwrite
    if [ -f "$PKIPATH/master.pem" ]; then
        cp -f "$PKIPATH/master.pem" "$PKIPATH/master.pem.old"
        chmod 400 "$PKIPATH/master.pem.old"
        chmod 600 "$PKIPATH/master.pem"
    fi
    # copy key over
    cp -f /root/master.pem "$PKIPATH/master.pem"
    # set destination to read only
    chmod 400 "$PKIPATH/master.pem"
fi

# copy over pubkey
if [ -f /root/master.pub ]; then
    if [ -f "$PKIPATH/master.pub" ]; then
        cp -f "$PKIPATH/master.pub" "$PKIPATH/master.pub.old"
    fi
    cp -f /root/master.pub "$PKIPATH/master.pub"
    chmod 644 "$PKIPATH/master.pub"
fi

# make sure ownership is correct
chown root:wheel "$PKIPATH"

# enable salt master
service salt_master enable || true
