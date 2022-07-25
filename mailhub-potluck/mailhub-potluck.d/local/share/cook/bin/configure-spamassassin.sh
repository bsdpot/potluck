#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# steps to setup spamassassin local.cf
< "$TEMPLATEPATH/spamassassin.local.cf.in" \
  sed "s${sep}%%dbname%%${sep}$MYSQLDB${sep}g" |\
  sed "s${sep}%%dbip%%${sep}$MYSQLIP${sep}g" |\
  sed "s${sep}%%dbuser%%${sep}$MYSQLUSER${sep}g" |\
  sed "s${sep}%%dbpassword%%${sep}$MYSQLPASS${sep}g" \
  > /usr/local/etc/mail/spamassassin/local.cf

# append whitelist addresses
if [ -f /root/spamassassin_whitelist ]; then
    while read -r line; do
        whitelistaddress="$line"
        echo "whitelist_from $whitelistaddress" >> /usr/local/etc/mail/spamassassin/local.cf
    done < /root/spamassassin_whitelist
fi

# setup cronjob for sa-update
echo "0  1  *  *  *  root  /usr/local/bin/sa-update && /usr/local/bin/sa-compile" >> /etc/crontab

# copy over script for cronjob
< "$TEMPLATEPATH/sa-training.sh.in" \
  sed "s${sep}%%vhostdir%%${sep}$VHOSTDIR${sep}g" \
  > /root/bin/sa-training.sh

# make executable
chmod +x /root/bin/sa-training.sh

# add cronjob for training
echo "0	11	*	*	1-5	root	/root/bin/sa-training.sh" >> /etc/crontab

# run sa-update and sa-compile
/usr/local/bin/sa-update && /usr/local/bin/sa-compile

# enable services
service sa-spamd enable
sysrc spamd_flags="-d -m5 -x -q -Q -u nobody -A $IP"
