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
  sed "s${sep}%%mailfromaddress%%${sep}$MAILFROM${sep}g" | \
  sed "s${sep}%%redishost%%${sep}$REDISHOST${sep}g" | \
  sed "s${sep}%%redisport%%${sep}$SETREDISPORT${sep}g" | \
  sed "s${sep}%%redispass%%${sep}$SETREDISPASS${sep}g" | \
  sed "s${sep}%%s3user%%${sep}$S3USER${sep}g" | \
  sed "s${sep}%%s3pass%%${sep}$S3PASS${sep}g" | \
  sed "s${sep}%%s3region%%${sep}$S3REGION${sep}g" | \
  sed "s${sep}%%s3bucket%%${sep}$S3BUCKET${sep}g" | \
  sed "s${sep}%%s3url%%${sep}$S3URL${sep}g" | \
  sed "s${sep}%%s3endpoint%%${sep}$S3ENDPOINT${sep}g" \
  > /usr/local/www/pixelfed/.env

# create storage link as www user
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan storage:link"

# function to check database
check_database() {
    /usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$DBPORT/postgres" -lqt | grep -c "$DBNAME"
}

# function to create database
create_db() {
	/usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$DBPORT/postgres" <<EOF
CREATE DATABASE "$DBNAME";
EOF
}

# if database exists, run artisan migrate, else create database, then run artisan migrate
dbcheck=$(check_database)

if [ "$dbcheck" -eq 1 ]; then
    echo "Configuring or upgrading Pixelfed database"
    su -m www -c "cd /usr/local/www/pixelfed && /usr/local/bin/php artisan migrate --force"
else
    echo "Database $DBNAME does not exist, creating database"
    if ! create_db; then
        echo "Failed to create database $DBNAME" >&2
        exit 1
    fi
    echo "Database $DBNAME created successfully"
    su -m www -c "cd /usr/local/www/pixelfed && /usr/local/bin/php artisan migrate --force"
fi

# import location data
echo "Importing cities"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan import:cities"

# enable activitypub features
echo "Enabling ActivityPub"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan instance:actor"

# update route cache
echo "Updating route cache"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan route:cache"

# update view cache
echo "Updating view cache"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan view:cache"

# update config
echo "Caching config"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan config:cache"

# install horizon
echo "Installing horizon"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan horizon:install"

# WARN Horizon no longer publishes its assets. You may stop calling the `horizon:publish` command.
#removed# su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/php artisan horizon:publish"

# configure supervisord.conf with program configuration to run horizon
echo "Setting up supervisord with program configuration for horizon"
cp -f "$TEMPLATEPATH/supervisord.conf.in" /usr/local/etc/supervisord.conf

# enable and the supervisord service to run horizon
service supervisord enable
