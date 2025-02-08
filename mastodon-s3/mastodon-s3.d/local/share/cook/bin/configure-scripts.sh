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

# make sure we have a /root/bin directory
mkdir -p /root/bin

# add check-cert.sh script
< "$TEMPLATEPATH/check-cert.sh.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /root/bin/check-cert.sh

# set executable permissions
chmod +x /root/bin/check-cert.sh

# add sendcertalert.sh script
< "$TEMPLATEPATH/sendcertalert.sh.in" \
  sed "s${sep}%%remotelogip%%${sep}$REMOTELOG${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /root/bin/sendcertalert.sh

# set executable permissions
chmod +x /root/bin/sendcertalert.sh

# add sendcertexpired.sh script
< "$TEMPLATEPATH/sendcertexpired.sh.in" \
  sed "s${sep}%%remotelogip%%${sep}$REMOTELOG${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /root/bin/sendcertexpired.sh

# set executable permissions
chmod +x /root/bin/sendcertexpired.sh

# add check-cert.sh script to /etc/crontab
echo "# Check SSL certificate every day" >> /etc/crontab
echo "0	12	*	*	*	root	/root/bin/check-cert.sh /usr/local/etc/ssl/fullchain.cer > /dev/null 2>&1" >> /etc/crontab
