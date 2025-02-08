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

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# make directories if they don't exist
mkdir -p /mnt/acme
mkdir -p /root/bin
mkdir -p /usr/local/www/acmetmp/

# the following is required for option --set-default-ca
mkdir -p /root/.acme.sh/
touch /root/.acme.sh/account.conf

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy over script for cronjob
< "$TEMPLATEPATH/update-certs.sh.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%email%%${sep}$EMAIL${sep}g" \
  > /root/bin/update-certs.sh

# set perms
chmod 750 /root/bin/update-certs.sh

# check if existing $DOMAIN and create certificates if not
if [ ! -d /mnt/acme/"$DOMAIN"_ecc/ ]; then
	/usr/local/sbin/acme.sh --register-account -m "$EMAIL" --home /mnt/acme --server letsencrypt
	/usr/local/sbin/acme.sh --set-default-ca --server letsencrypt
	/usr/local/sbin/acme.sh --issue -d "$DOMAIN" --server letsencrypt \
	 --home /mnt/acme --standalone --listen-v4 --httpport 80 --log /mnt/acme/acme.sh.log || true
	if [ ! -f /mnt/acme/"$DOMAIN"_ecc/"$DOMAIN".cer ]; then
		echo "Trying to register cert again, sleeping 30"
		sleep 30
		/usr/local/sbin/acme.sh --issue -d "$DOMAIN" --server letsencrypt \
		 --home /mnt/acme --standalone --listen-v4 --httpport 80 --log /mnt/acme/acme.sh.log || true
		if [ ! -f /mnt/acme/"$DOMAIN"_ecc/"$DOMAIN".cer ]; then
			echo "missing $DOMAIN.cer, certificate not registered"
			exit 1
		fi
	fi
	# try continue, with a cert hopefully
	cd /mnt/acme/"$DOMAIN"_ecc/ || true
	cp -Rf /mnt/acme/"$DOMAIN"_ecc/ /usr/local/etc/ssl/
else
	echo "/mnt/acme/$DOMAIN _ecc exists, not creating certificates"
	# try continue, with a cert hopefully
	cd /mnt/acme/"$DOMAIN"_ecc/ || true
	cp -Rf /mnt/acme/"$DOMAIN"_ecc/ /usr/local/etc/ssl/
fi
