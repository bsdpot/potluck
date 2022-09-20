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

# make directories if not existing
mkdir -p /mnt/opendkim/keys

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# steps to setup opendkim
< "$TEMPLATEPATH/opendkim.conf.in" \
  sed "s${sep}%%signdomains%%${sep}$SIGNDOMAINS${sep}g" \
  > /usr/local/etc/mail/opendkim.conf

# copy in TrustedHosts, your copied in file must include 127.0.0.0/8 and 10.0.0.0/8
if [ ! -f /mnt/opendkim/TrustedHosts ]; then
    if [ -f /root/dkim_trusted_hosts ]; then
        cp -f /root/dkim_trusted_hosts /mnt/opendkim/TrustedHosts
    else
        echo "127.0.0.0/8" > /mnt/opendkim/TrustedHosts
        echo "10.0.0.0/8" >> /mnt/opendkim/TrustedHosts
    fi
fi

# generate dkim files from imported list of domains
if [ -f /root/dkim_my_domains ]; then
    while read -r line; do
        dkimdomain="$line"
        if [ ! -d /mnt/opendkim/keys/"$dkimdomain" ]; then
            mkdir -p /mnt/opendkim/keys/"$dkimdomain"
            /usr/local/sbin/opendkim-genkey --domain="$dkimdomain" --directory=/mnt/opendkim/keys/"$dkimdomain"
            echo "default._domainkey.$dkimdomain $dkimdomain:default:/mnt/opendkim/keys/$dkimdomain/default" >> /mnt/opendkim/KeyTable
            echo "*@$dkimdomain default._domainkey.$dkimdomain" >> /mnt/opendkim/SigningTable
        fi
    done < /root/dkim_my_domains
fi

# permissions
if [ -d /mnt/opendkim ]; then
    if [ -f /mnt/opendkim/KeyTable ]; then
        chmod 640 /mnt/opendkim/KeyTable
    fi
    if [ -f /mnt/opendkim/SigningTable ]; then
        chmod 640 /mnt/opendkim/SigningTable
    fi
    if [ -f /mnt/opendkim/TrustedHosts ]; then
        chmod 640 /mnt/opendkim/TrustedHosts
    fi
    if [ -d /mnt/opendkim/keys ]; then
        chmod 750 /mnt/opendkim/keys
    fi
fi

# enable and start service
service milter-opendkim enable
#service milter-opendkim start
