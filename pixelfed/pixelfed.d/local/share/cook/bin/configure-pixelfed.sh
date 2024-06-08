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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# check for existing app key in file, else generate one
if [ -f /mnt/private/.myappkey ]; then
	MYAPPKEY=$(cat /mnt/private/.myappkey)
else
	/usr/bin/openssl rand -base64 32 > /mnt/private/.myappkey
	MYAPPKEY=$(cat /mnt/private/.myappkey)
fi
export MYAPPKEY

# copy in custom env.production
< "$TEMPLATEPATH/env.production.in" \
  sed "s${sep}%%appname%%${sep}$APPNAME${sep}g" | \
  sed "s${sep}%%myappkey%%${sep}$MYAPPKEY${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%dbhost%%${sep}$DBHOST${sep}g" | \
  sed "s${sep}%%dbport%%${sep}$DBPORT${sep}g" | \
  sed "s${sep}%%dbname%%${sep}$DBNAME${sep}g" | \
  sed "s${sep}%%dbuser%%${sep}$DBUSER${sep}g" | \
  sed "s${sep}%%dbpass%%${sep}$DBPASS${sep}g" | \
  sed "s${sep}%%mailhost%%${sep}$MAILHOST${sep}g" | \
  sed "s${sep}%%mailport%%${sep}$MAILPORT${sep}g" | \
  sed "s${sep}%%mailuser%%${sep}$MAILUSER${sep}g" | \
  sed "s${sep}%%mailpass%%${sep}$MAILPASS${sep}g" | \
  sed "s${sep}%%mailfromaddress%%${sep}$MAILFROM{sep}g" | \
  sed "s${sep}%%s3user%%${sep}$S3USER${sep}g" | \
  sed "s${sep}%%s3pass%%${sep}$S3PASS${sep}g" | \
  sed "s${sep}%%s3region%%${sep}$S3REGION${sep}g" | \
  sed "s${sep}%%s3bucket%%${sep}$S3BUCKET${sep}g" | \
  sed "s${sep}%%s3url%%${sep}$S3URL${sep}g" | \
  sed "s${sep}%%s3endpoint%%${sep}$S3ENDPOINT${sep}g" \
  > /usr/local/www/pixelfed/.env

# create storage link as www user
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan storage:link"

# perform database create or migrations (pixelfed db user must already exist with createdb permissions)
# this is a redundant if/else because it's the same either way
# this might need work still
dbcheck=$(/usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$DBPORT/postgres" -lqt | grep -c "$DBNAME")
if [ "$dbcheck" -eq "0" ]; then
	echo "Setting up pixelfed database"
	su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan migrate --force"
else
	echo "Upgrading pixelfed database"
	su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan migrate --force"
fi

# location data
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan import:cities"

# enable activitypub features
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan instance:actor"

# update route cache
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan route:cache"

# update view cache
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan view:cache"

# update config
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan config:cache"

# install horizon
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan horizon:install"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan horizon:publish"

# configure supervisord.conf with program configuration to run horizon
cp -f "$TEMPLATEPATH/supervisord.conf.in" /usr/local/etc/supervisord.conf

# enable and the supervisord service to run horizon
service supervisord enable
