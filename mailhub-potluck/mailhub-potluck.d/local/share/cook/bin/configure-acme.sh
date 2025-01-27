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

# make directories if they don't exist
mkdir -p /mnt/acme

# the following is required for option --set-default-ca
mkdir -p /root/.acme.sh/
touch /root/.acme.sh/account.conf

# shellcheck disable=SC3003,SC2039
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
if [ ! -d /mnt/acme/"$MAILCERTDOMAIN"_ecc ]; then
    service postfix onestop || true
    #/usr/local/sbin/acme.sh --register-account -m "$POSTMASTERADDRESS" --home /mnt/acme --server zerossl
    /usr/local/sbin/acme.sh --register-account -m "$POSTMASTERADDRESS" --home /mnt/acme --server letsencrypt
    /usr/local/sbin/acme.sh --set-default-ca --server letsencrypt
    /usr/local/sbin/acme.sh --issue -d "$MAILCERTDOMAIN" --server letsencrypt \
      --home /mnt/acme --standalone --listen-v4 --httpport 80 --log /mnt/acme/acme.sh.log || true
    if [ ! -f /mnt/acme/"$MAILCERTDOMAIN"_ecc/"$MAILCERTDOMAIN".cer ]; then
        echo "Trying to register cert again, sleeping 30"
        sleep 30
        /usr/local/sbin/acme.sh --issue -d "$MAILCERTDOMAIN" --server letsencrypt \
          --home /mnt/acme --standalone --listen-v4 --httpport 80 --log /mnt/acme/acme.sh.log || true
        if [ ! -f /mnt/acme/"$MAILCERTDOMAIN"_ecc/"$MAILCERTDOMAIN".cer ]; then
            echo "missing $MAILCERTDOMAIN.cer, certificate not registered"
            exit 1
        fi
    fi
    # try continue, with a cert hopefully
    cd /mnt/acme/"$MAILCERTDOMAIN"_ecc/ || exit 1
    if [ -d /usr/local/etc/postfix/keys/ ]; then
        cp -f ./* /usr/local/etc/postfix/keys/
        cd /usr/local/etc/postfix/keys/
        if [ -f "$MAILCERTDOMAIN".cer ]; then
            mv -f "$MAILCERTDOMAIN".cer "$MAILCERTDOMAIN".crt
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
    echo "/mnt/acme/$MAILCERTDOMAIN _ecc exists, not creating certificates, importing existing certs to postfix"
    # try continue, with a cert hopefully
    cd /mnt/acme/"$MAILCERTDOMAIN"_ecc/ || exit 1
    if [ -d /usr/local/etc/postfix/keys/ ]; then
        cp -f ./* /usr/local/etc/postfix/keys/
        cd /usr/local/etc/postfix/keys/
        if [ -f "$MAILCERTDOMAIN".cer ]; then
            mv -f "$MAILCERTDOMAIN".cer "$MAILCERTDOMAIN".crt
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
fi
