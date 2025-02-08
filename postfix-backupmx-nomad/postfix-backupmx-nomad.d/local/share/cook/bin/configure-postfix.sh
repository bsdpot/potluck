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

# make necessary directories
mkdir -p /usr/local/etc/postfix
mkdir -p /usr/local/etc/mail

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in syslog-ng.conf
# shellcheck disable=SC2039
< "$TEMPLATEPATH/main.cf.in" \
  sed "s${sep}%%myhostname%%${sep}$HOSTNAME${sep}g" | \
  sed "s${sep}%%mynetworks%%${sep}$MYNETWORKS${sep}g" | \
  sed "s${sep}%%relaydomains%%${sep}$RELAYDOMAINS${sep}g" | \
  sed "s${sep}%%smtpdbanner%%${sep}$SMTPDBANNER${sep}g" \
  > /usr/local/etc/postfix/main.cf

# setup mailer.conf from template
install -m 0644 /usr/local/share/postfix/mailer.conf.postfix /usr/local/etc/mail/mailer.conf

# remove sendmail tasks from periodic.conf
#sysrc -f /etc/periodic.conf daily_clean_hoststat_enable="NO"
#sysrc -f /etc/periodic.conf daily_status_mail_rejects_enable="NO"
#sysrc -f /etc/periodic.conf daily_status_include_submit_mailq="NO"
#sysrc -f /etc/periodic.conf daily_submit_queuerun="NO"

# enable service?
sysrc sendmail_enable="NONE"
service postfix enable

# run newaliases
#newliases
postalias /etc/aliases
