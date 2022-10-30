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

# make directories if they don't exist
mkdir -p /mnt/acme

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# copy over script for cronjob
< "$TEMPLATEPATH/update-mail-certs.sh.in" \
  sed "s${sep}%%mailcertdomain%%${sep}$MAILCERTDOMAIN${sep}g" | \
  sed "s${sep}%%postmasteraddress%%${sep}$POSTMASTERADDRESS${sep}g" \
  > /root/bin/update-mail-certs.sh

# set perms
chmod 750 /root/bin/update-mail-certs.sh

# check if no existing $MAILCERTDOMAIN and create certificates if not
if [ ! -d /mnt/acme/"$MAILCERTDOMAIN" ]; then
    service postfix onestop || true
    #/usr/local/sbin/acme.sh --register-account -m "$POSTMASTERADDRESS" --home /mnt/acme --server zerossl
    /usr/local/sbin/acme.sh --register-account -m "$POSTMASTERADDRESS" --home /mnt/acme --server letsencrypt
    /usr/local/sbin/acme.sh --issue -d "$MAILCERTDOMAIN" --server letsencrypt \
      --home /mnt/acme --standalone --listen-v4 --httpport 80 --insecure
    cd /mnt/acme/"$MAILCERTDOMAIN"/
    if [ -d /usr/local/etc/postfix/keys/ ]; then
        cp ./* /usr/local/etc/postfix/keys/
        cd /usr/local/etc/postfix/keys/
        if [ -f "$MAILCERTDOMAIN".cer ]; then
            mv "$MAILCERTDOMAIN".cer "$MAILCERTDOMAIN".crt
        else
            echo "Error, missing $MAILCERTDOMAIN.cer file"
            exit 1
        fi
        if [ -f ca.cer ] && [ -f "$MAILCERTDOMAIN".crt ]; then
            cat ca.cer >> "$MAILCERTDOMAIN".crt
        else
            echo "Error, missing ca.cer file"
            exit 1
        fi
    else
        echo "/usr/local/etc/postfix/keys/ does not exist"
        exit 1
    fi
else
    echo "/mnt/acme/$MAILCERTDOMAIN exists, not creating certificates"
fi
