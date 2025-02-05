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

# copy header file and replace domain
< "$TEMPLATEPATH/header.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /root/header.in

# remove the example file
rm /usr/local/etc/rbldnsd/example

# get the blocklist from github
#git clone https://github.com/borestad/blocklist-ip.git /root/blocklist-ip
# updated 2024-08-18, see https://github.com/bsdpot/potluck/issues/55
git clone https://github.com/borestad/blocklist-abuseipdb.git /root/blocklist-ip

# check ruleset or set default
if [ -n "$RULESET" ]; then
	# shellcheck disable=SC2269
	RULESET="$RULESET"
else
	RULESET="30"
fi

case $RULESET in
1) RULEFILE="/root/blocklist-ip/abuseipdb-s100-1d.ipv4" ;;
3) RULEFILE="/root/blocklist-ip/abuseipdb-s100-3d.ipv4" ;;
7) RULEFILE="/root/blocklist-ip/abuseipdb-s100-7d.ipv4" ;;
14) RULEFILE="/root/blocklist-ip/abuseipdb-s100-14d.ipv4" ;;
30) RULEFILE="/root/blocklist-ip/abuseipdb-s100-30d.ipv4" ;;
60) RULEFILE="/root/blocklist-ip/abuseipdb-s100-60d.ipv4" ;;
90) RULEFILE="/root/blocklist-ip/abuseipdb-s100-90d.ipv4" ;;
120) RULEFILE="/root/blocklist-ip/abuseipdb-s100-120d.ipv4" ;;
all) RULEFILE="/root/blocklist-ip/abuseipdb-s100-all.ipv4" ;;
*)
  echo "there is a problem with the RULESET parameter"
  exit 1
  ;;
esac

# cat header and blocklist to /usr/local/etc/rbldnsd/$DOMAIN
header="/root/header.in"
if [ -f "$header" ] && [ -f "$RULEFILE" ]; then
	#cp -f "$RULEFILE" "/usr/local/etc/rbldnsd/$DOMAIN"
	cat "$header" "$RULEFILE" > "/usr/local/etc/rbldnsd/$DOMAIN"
else
	echo "The rules file is missing."
	exit 1
fi

# setup script to update rules regularly
< "$TEMPLATEPATH/updatelist.sh.in" \
  sed "s${sep}%%rulefile%%${sep}$RULEFILE${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /usr/local/bin/updatelist.sh

# set executable permissions
chmod +x /usr/local/bin/updatelist.sh

# add to cron every 8 hours
echo "# Update IP blocklist every 8 hours" >> /etc/crontab
echo "0	*/8	*	*	*	root	/usr/local/bin/updatelist.sh" >> /etc/crontab

# set options
sysrc rbldnsd_flags="-r /usr/local/etc/rbldnsd -b $IP bl.$DOMAIN:ip4tset:$DOMAIN"

# enable rbldnsd
service rbldnsd enable || true
