#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# make directories if they don't exist
mkdir -p /usr/local/etc/postfix/keys
mkdir -p /mnt/postfix

# set ownership to postfix user
chown -R postfix:postfix /mnt/postfix

# create missing /etc/mail/certs/dh.param
# this is not relevant to postfix but used by sm-mta and causes error if not existing
if [ -d /etc/mail/certs ] && [ ! -f /etc/mail/certs/dh.param ]; then
    /usr/bin/openssl dhparam -out /etc/mail/certs/dh.param 2048
fi

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# set optional parameter for message size limits
if [ -z "$POSTSIZELIMIT" ]; then
  POSTSIZELIMIT=536870912
fi

# %%datadirectory%%
# POSTDATADIR=
# /var/db/postfix
# /mnt/postfix
#
# %%mynetworks%%
# POSTNETWORKS=
#  127.0.0.0/8, 10.0.0.0/8, host/mask, host/mask
#
# %%vmailboxdomains%%
# POSTDOMAINS=
#  domain.tld, other.com, newdomain.sh
#
# %%messagesizelimit%%
# POSTSIZELIMIT=
#  536870912
#
# %%mailcertdomain%%
# MAILCERTDOMAIN=
#  mail.domain.tld
#
# add main.cf with custom variables
< "$TEMPLATEPATH/postfix-main.cf.in" \
  sed "s${sep}%%datadirectory%%${sep}$POSTDATADIR${sep}g" | \
  sed "s${sep}%%mynetworks%%${sep}$POSTNETWORKS${sep}g" | \
  sed "s${sep}%%vmailboxdomains%%${sep}$POSTDOMAINS${sep}g" | \
  sed "s${sep}%%messagesizelimit%%${sep}$POSTSIZELIMIT${sep}g" | \
  sed "s${sep}%%mailcertdomain%%${sep}$MAILCERTDOMAIN${sep}g" \
  > /usr/local/etc/postfix/main.cf

# %%ldapserver%%
# LDAPSERVER=
#  1.2.3.4
#
# %%searchbase%%
# SEARCHBASE=
#  ou=People,dc=domain,dc=tld
#
# add virtual_alias_maps.cf with custom variables
< "$TEMPLATEPATH/virtual_alias_maps.cf.in" \
  sed "s${sep}%%ldapserver%%${sep}$LDAPSERVER${sep}g" | \
  sed "s${sep}%%searchbase%%${sep}$SEARCHBASE${sep}g" \
  > /usr/local/etc/postfix/virtual_alias_maps.cf

# %%ldapserver%%
# LDAPSERVER=
#  1.2.3.4
#
# %%searchbase%%
# SEARCHBASE=
#  ou=People,dc=domain,dc=tld
#
# add virtual_mailbox_maps.cf with custom variables
< "$TEMPLATEPATH/virtual_mailbox_maps.cf.in" \
  sed "s${sep}%%ldapserver%%${sep}$LDAPSERVER${sep}g" | \
  sed "s${sep}%%searchbase%%${sep}$SEARCHBASE${sep}g" \
  > /usr/local/etc/postfix/virtual_mailbox_maps.cf

# configure /usr/local/etc/postfix/access by copying over the copied-in file
# example has
#  demo.sophimail.com    REJECT
#
if [ -f /root/postfix_access ]; then
    cp -f /root/postfix_access /usr/local/etc/postfix/access
    /usr/local/sbin/postmap /usr/local/etc/postfix/access
fi

# configure /usr/local/etc/postfix/external_forwards by copying over the copied-in file
# example has
#  address@domain.com  address@gmail.com
#
if [ -f /root/postfix_external_forwards ]; then
    cp -f /root/postfix_external_forwards /usr/local/etc/postfix/external_forwards
    /usr/local/sbin/postmap /usr/local/etc/postfix/external_forwards
fi

# configure /usr/local/etc/postfix/sender_transport
# example has
#  @demo.sophimail.com   demo_com:
#
if [ -f /root/postfix_sender_transport ]; then
    cp -f /root/postfix_sender_transport /usr/local/etc/postfix/sender_transport
    /usr/local/sbin/postmap /usr/local/etc/postfix/sender_transport
fi

# other mailer configuration
if [ ! -d /usr/local/etc/mail ]; then
    mkdir -p /usr/local/etc/mail
fi

if [ -f /usr/local/share/postfix/mailer.conf.postfix ]; then
    install -m 0644 /usr/local/share/postfix/mailer.conf.postfix /usr/local/etc/mail/mailer.conf
fi

# disable old mail services and enable postfix
sysrc sendmail_submit_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_msp_queue_enable="NO"
service postfix enable

# enable rootmail alias
if [ -n "$ROOTMAIL" ]; then
    if [ -f /etc/aliases ]; then
        echo "root: $ROOTMAIL" >> /etc/aliases
        /usr/bin/newaliases
    fi
fi
