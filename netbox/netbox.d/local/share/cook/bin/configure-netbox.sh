#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH="/usr/local/bin:$PATH"

# ensure necessary directories are present
mkdir -p /mnt/netboxdata/media/devicetype-images
mkdir -p /mnt/netboxdata/media/image-attachments
chown www:www /mnt/netboxdata/media/devicetype-images
chown www:www /mnt/netboxdata/media/image-attachments

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# create a secretkey for netbox using provided tool and save to file for future usage
if [ -f /mnt/netboxdata/secret.key ]; then
  SECRETKEY=$(cat /mnt/netboxdata/secret.key)
else
  /usr/local/bin/python3.11 /usr/local/share/netbox/generate_secret_key.py > /mnt/netboxdata/secret.key
  SECRETKEY=$(cat /mnt/netboxdata/secret.key)
fi

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# setup the netbox configuration file
< "$TEMPLATEPATH/configuration.py.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%dbname%%${sep}$DBNAME${sep}g" | \
  sed "s${sep}%%dbuser%%${sep}$DBUSER${sep}g" | \
  sed "s${sep}%%dbpasswd%%${sep}$DBPASSWORD${sep}g" | \
  sed "s${sep}%%dbhost%%${sep}$DBHOST${sep}g" | \
  sed "s${sep}%%dbport%%${sep}$SETDBPORT${sep}g" | \
  sed "s${sep}%%redishost%%${sep}$REDISHOST${sep}g" | \
  sed "s${sep}%%redisport%%${sep}$SETREDISPORT${sep}g" | \
  sed "s${sep}%%secretkey%%${sep}$SECRETKEY${sep}g" | \
  sed "s${sep}%%adminname%%${sep}$ADMINNAME${sep}g" | \
  sed "s${sep}%%adminemail%%${sep}$ADMINEMAIL${sep}g" | \
  sed "s${sep}%%mailserver%%${sep}$MAILSERVER${sep}g" | \
  sed "s${sep}%%smtpport%%${sep}$SETMAILPORT${sep}g" | \
  sed "s${sep}%%mailusername%%${sep}$MAILUSERNAME${sep}g" | \
  sed "s${sep}%%mailpassword%%${sep}$MAILPASSWORD${sep}g" | \
  sed "s${sep}%%frommail%%${sep}$FROMMAIL${sep}g" \
  > /usr/local/share/netbox/netbox/configuration.py

# set permissions for www owner on netbox.conf.py
chown www:wheel /usr/local/share/netbox/netbox/configuration.py
chmod 640 /usr/local/share/netbox/netbox/configuration.py

# copy over the RC file for netbox
cp -f "$TEMPLATEPATH/netbox.rc.in" /usr/local/etc/rc.d/netbox
chmod 555 /usr/local/etc/rc.d/netbox

# setup the netbox gunicorn template
cp -f "$TEMPLATEPATH/netbox.conf.py.in" /usr/local/etc/netbox.conf.py
chown www /usr/local/etc/netbox.conf.py
chmod 640 /usr/local/etc/netbox.conf.py

# unclear if needed, do not start
service gunicorn enable

# set load parameter for netbox config
service netbox enable
sysrc netbox_config="/usr/local/etc/netbox.conf.py"
sysrc netbox_use_config="YES"

# setup housekeeping
cp -f "$TEMPLATEPATH/850.netbox-housekeeping.in" /usr/local/etc/periodic/daily/850.netbox-housekeeping
chmod 755 /usr/local/etc/periodic/daily/850.netbox-housekeeping
sysrc -f /etc/periodic.conf daily_netbox_housekeeping_enable="YES"

# Removing for now
#
# # unset this
# set +e
# # shellcheck disable=SC3040
# set +o pipefail

# # database check as formality
# dbcheck=$(/usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$DBPORT/postgres" -lqt | grep -c "$DBNAME")

# if [ "$dbcheck" -eq "0" ]; then
# 	echo "Database $DBNAME not found on $DBHOST:$DBPORT"
# 	exit 1
# fi
