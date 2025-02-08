#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# If we do not find a Nextcloud installation, we install it. If we do find something though,
# we do not install/overwrite anything as we assume that updates/modifications are happening
# from within the Nextcloud installation.
if [ ! -e /usr/local/www/nextcloud/status.php ]; then
	# make sure we have a directory
	mkdir -p /usr/local/www/nextcloud
	# set permissions
	chown -R www:www /usr/local/www/nextcloud
	# initialise git repo
	su -m www -c 'cd /usr/local/www/nextcloud; git init' || true
	# add remote origin
	su -m www -c 'cd /usr/local/www/nextcloud; git remote add origin https://github.com/nextcloud/server.git' || true
	# fetch git sources, 5GB download
	su -m www -c 'cd /usr/local/www/nextcloud; git fetch' || true
	# check out the commit we want
	su -m www -c "cd /usr/local/www/nextcloud; git checkout ${FROMGITHUB}" || true
	# make necessary directories for freebsd setup
	su -m www -c 'mkdir -p /usr/local/www/nextcloud/apps' || true
	su -m www -c 'mkdir -p /usr/local/www/nextcloud/apps-pkg' || true
	# get 3rdparty packages required
	su -m www -c 'cd /usr/local/www/nextcloud; git submodule update --init' || true
	# custom config setup
	if [ -f /usr/local/www/nextcloud/config/config.php ]; then
		mv /usr/local/www/nextcloud/config/config.php /usr/local/www/nextcloud/config/config.php.potbak
		touch /usr/local/www/nextcloud/config/config.php
		chown www:www /usr/local/www/nextcloud/config/config.php
		chmod 660 /usr/local/www/nextcloud/config/config.php
	fi
fi
