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

# make directories if not exist
mkdir -p /mnt/dovecot/mail
mkdir -p /mnt/dovecot/sieve/before.d/

# This should be a file with
# #<identifier> <ACLs> [:<named ACLs>]
# # options: l lookup, r read, w write, s write-seen,
# # t write-deleted, i insert, p post, e expunge,
# # k create, x delete, a administration rights
# public/TestFolder user=username lrwstipekxa
# #owner lrwstipekxa
# # allow anyone to list and read a public mailbox
# public/* user=username lr
# # Prevent all users from deleting their Spam folder
# #INBOX.Spam owner lrwstipeka
#############
touch /usr/local/etc/dovecot/global-acls

# create vhost user and group
# create Dovecot Virtual Mail User
pw groupadd -n vhost -g 3000
pw useradd -n vhost -u 3000 -g vhost -d /mnt/dovecot -s /usr/sbin/nologin -h - -c "Dovecot Virtual Mail User"

# add dovecot user to vhost group
pw usermod dovecot -G vhost

# change permissions
chown -R vhost:vhost /mnt/dovecot

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# setup dovecot.conf
< "$TEMPLATEPATH/dovecot.conf.in" \
  sed "s${sep}%%mailcertdomain%%${sep}$MAILCERTDOMAIN${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%vhostdir%%${sep}$VHOSTDIR${sep}g" | \
  sed "s${sep}%%postmastermail%%${sep}$POSTMASTERADDRESS${sep}g" \
  > /usr/local/etc/dovecot/dovecot.conf

# setup dovecot-ldap.conf.ext with ldap servers and base
< "$TEMPLATEPATH/dovecot-ldap.conf.ext.in" \
  sed "s${sep}%%ldapserver%%${sep}$LDAPSERVER${sep}g" | \
  sed "s${sep}%%searchbase%%${sep}$SEARCHBASE${sep}g" \
  > /usr/local/etc/dovecot/dovecot-ldap.conf.ext

# unset ssl settings
sed -i .bak \
    -e "s${sep}ssl_cert =${sep}#ssl_cert =${sep}g" \
    -e "s${sep}ssl_key =${sep}#ssl_key =${sep}g" \
    /usr/local/etc/dovecot/conf.d/10-ssl.conf

# set ldap auth
sed -i .bak \
    -e "s${sep}!include auth-system.conf.ext${sep}#!include auth-system.conf.ext${sep}g" \
    -e "s${sep}#!include auth-ldap.conf.ext${sep}!include auth-ldap.conf.ext${sep}g" \
    /usr/local/etc/dovecot/conf.d/10-auth.conf

# enable dovecot
service dovecot enable
sysrc dovecot_config="/usr/local/etc/dovecot/dovecot.conf"
