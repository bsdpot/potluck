#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# check that redis is active
echo "Checking for an active redis server"
redischeck=$(/usr/local/bin/redis-cli -h "$REDISHOST" ping |grep -c PONG)
if [ "$redischeck" -eq "1" ]; then
	echo "Redis server found, continuing"
else
	echo "Cannot reach redis server, is it running?"
	exit 1
fi

# make directory to store keys
mkdir -p /mnt/mastodon/private

# set permissions on key directory after creating user
chown -R mastodon:mastodon /mnt/mastodon/

# move this up
SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

# generate a rake secret if the file /mnt/mastodon/private/secret.key doesn't exist
# we now use rails to generate the key instead of rake
# shellcheck disable=SC2153
if [ -f /mnt/mastodon/private/secret.key ]; then
	echo "Secret key exists, not creating"
	SECRETKEY=$(cat /mnt/mastodon/private/secret.key)
else
	if [ -n "$MYSECRETKEY" ]; then
		echo "Saving passed in secret key"
		echo "$MYSECRETKEY" > /mnt/mastodon/private/secret.key
		SECRETKEY=$(cat /mnt/mastodon/private/secret.key)
	else
		echo "Creating a secret key, this takes a few seconds"
		su - mastodon -c 'cd /usr/local/www/mastodon && RAILS_ENV=production /usr/local/bin/bundle exec rails secret > /mnt/mastodon/private/secret.key'
		SECRETKEY=$(cat /mnt/mastodon/private/secret.key)
	fi
fi

# generate OTP secret if the file /mnt/mastodon/private/otp.key doesn't exist
# we now use rails to generate the key instead of rake
# shellcheck disable=SC2153
if [ -f /mnt/mastodon/private/otp.key ]; then
	echo "OTP exists, not creating"
	OTPSECRET=$(cat /mnt/mastodon/private/otp.key)
else
	if [ -n "$MYOTPSECRET" ]; then
		echo "Saving passed in OTP key"
		echo "$MYOTPSECRET" > /mnt/mastodon/private/otp.key
		OTPSECRET=$(cat /mnt/mastodon/private/otp.key)
	else
		echo "Creating OTP key, this takes a few seconds"
		su - mastodon -c 'cd /usr/local/www/mastodon && RAILS_ENV=production /usr/local/bin/bundle exec rails secret > /mnt/mastodon/private/otp.key'
		OTPSECRET=$(cat /mnt/mastodon/private/otp.key)
	fi
fi

# generate vapid keys if the file /mnt/mastodon/private/vapid.keys doesn't exist
# shellcheck disable=SC2153
if [ -f /mnt/mastodon/private/vapid.keys ]; then
	echo "VAPID keys exist, not creating"
	VAPIDPRIVATEKEY=$(grep VAPID_PRIVATE_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
	VAPIDPUBLICKEY=$(grep VAPID_PUBLIC_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
else
	if [ -n "$MYVAPIDPRIVATEKEY" ] && [ -n "$MYVAPIDPUBLICKEY" ]; then
		echo "Passing vapid keys to new file"
		< "$TEMPLATEPATH/vapid.keys.in" \
		sed "s${sep}%%myvapidprivatekey%%${sep}$MYVAPIDPRIVATEKEY${sep}g" | \
		sed "s${sep}%%myvapidpublickey%%${sep}$MYVAPIDPUBLICKEY${sep}g" \
		> /mnt/mastodon/private/vapid.keys
	else
		echo "Creating Vapid keys"
		su - mastodon -c 'cd /usr/local/www/mastodon && RAILS_ENV=production /usr/local/bin/bundle exec rake mastodon:webpush:generate_vapid_key > /mnt/mastodon/private/vapid.keys'
	fi
	VAPIDPRIVATEKEY=$(grep VAPID_PRIVATE_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
	VAPIDPUBLICKEY=$(grep VAPID_PUBLIC_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
fi

# make sure permissions are correct
chown -R mastodon:mastodon /mnt/mastodon/private/

echo "Creating .env.production"

# copy in custom mastodon environment file
< "$TEMPLATEPATH/env.production.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%secretkey%%${sep}$SECRETKEY${sep}g" | \
  sed "s${sep}%%otpsecret%%${sep}$OTPSECRET${sep}g" | \
  sed "s${sep}%%vapidprivatekey%%${sep}$VAPIDPRIVATEKEY${sep}g" | \
  sed "s${sep}%%vapidpublickey%%${sep}$VAPIDPUBLICKEY${sep}g" | \
  sed "s${sep}%%redishost%%${sep}$REDISHOST${sep}g" | \
  sed "s${sep}%%redisport%%${sep}$SETREDISPORT${sep}g" | \
  sed "s${sep}%%dbhost%%${sep}$DBHOST${sep}g" | \
  sed "s${sep}%%dbuser%%${sep}$DBUSER${sep}g" | \
  sed "s${sep}%%dbpass%%${sep}$DBPASS${sep}g" | \
  sed "s${sep}%%dbname%%${sep}$DBNAME${sep}g" | \
  sed "s${sep}%%dbport%%${sep}$SETDBPORT${sep}g" | \
  sed "s${sep}%%mailhost%%${sep}$MAILHOST${sep}g" | \
  sed "s${sep}%%mailport%%${sep}$SETMAILPORT${sep}g" | \
  sed "s${sep}%%mailuser%%${sep}$MAILUSER${sep}g" | \
  sed "s${sep}%%mailpass%%${sep}$MAILPASS${sep}g" | \
  sed "s${sep}%%mailfrom%%${sep}$MAILFROM${sep}g" | \
  sed "s${sep}%%bucket%%${sep}$BUCKETHOST${sep}g" | \
  sed "s${sep}%%s3hostname%%${sep}$S3HOSTNAME${sep}g" | \
  sed "s${sep}%%s3user%%${sep}$BUCKETUSER${sep}g" | \
  sed "s${sep}%%s3pass%%${sep}$BUCKETPASS${sep}g" | \
  sed "s${sep}%%region%%${sep}$BUCKETREGION${sep}g" | \
  sed "s${sep}%%aliashost%%${sep}$BUCKETALIAS${sep}g" | \
  sed "s${sep}%%elasticenable%%${sep}$SETELASTICENABLE${sep}g" | \
  sed "s${sep}%%elastichost%%${sep}$SETELASTICHOST${sep}g" | \
  sed "s${sep}%%elasticport%%${sep}$SETELASTICPORT${sep}g" | \
  sed "s${sep}%%elasticuser%%${sep}$SETELASTICUSER${sep}g" | \
  sed "s${sep}%%elasticpass%%${sep}$SETELASTICPASS${sep}g" | \
  sed "s${sep}%%deepltranslatekey%%${sep}$SETDEEPLKEY${sep}g" | \
  sed "s${sep}%%deepltranslateplan%%${sep}$SETDEEPLPLAN${sep}g" \
  > /usr/local/www/mastodon/.env.production

# set permissions on the file
echo "Setting permissions on env file"
chown mastodon:mastodon /usr/local/www/mastodon/.env.production

# make a backup of .env.production in /mnt/mastodon/private
if [ -f /mnt/mastodon/private/backup.env.production ]; then
	mv -f /mnt/mastodon/private/backup.env.production /mnt/mastodon/private/backup.env.production.old
fi
# copy our .env.production to backup
cp -f /usr/local/www/mastodon/.env.production /mnt/mastodon/private/backup.env.production

# removed as not in use, we'll rebuild the image each time
# and upgrade the database during boot
# copy in upgrade script to /root/upgrade-mastodon.sh
#< "$TEMPLATEPATH/upgrade-mastodon.sh.in" \
#  sed "s${sep}%%redishost%%${sep}$REDISHOST${sep}g" | \
#  sed "s${sep}%%dbuser%%${sep}$DBUSER${sep}g" | \
#  sed "s${sep}%%dbpass%%${sep}$DBPASS${sep}g" | \
#  sed "s${sep}%%dbhost%%${sep}$DBHOST${sep}g" | \
#  sed "s${sep}%%dbport%%${sep}$SETDBPORT${sep}g" | \
#  sed "s${sep}%%dbname%%${sep}$DBNAME${sep}g" \
#  > /root/upgrade-mastodon.sh
## set permissions on upgrade script
#chmod 750 /root/upgrade-mastodon.sh

# remote command database check
# with bash we can set the shell variable PGPASSWORD="$DBPASS" and run psql without
# being asked for a password.
# with csh we must use the connect string and query postgres db
echo "Checking remote database access"

# unset this
set +e
# shellcheck disable=SC3040
set +o pipefail

# if the database doesn't exist we create it, if it does we upgrade it
dbcheck=$(/usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$DBPORT/postgres" -lqt | grep -c "$DBNAME")
if [ "$dbcheck" -eq "0" ]; then
	echo "Setting up a new database"
	su - mastodon -c '/usr/local/bin/bash -c "cd /usr/local/www/mastodon; RAILS_ENV=production SAFETY_ASSURED=1 /usr/local/bin/bundle exec rails db:setup"'
else
    echo "Running pre-deployment database migrations"
    su - mastodon -c '/usr/local/bin/bash -c "cd /usr/local/www/mastodon; SKIP_POST_DEPLOYMENT_MIGRATIONS=true RAILS_ENV=production SAFETY_ASSURED=1 /usr/local/bin/bundle exec rails db:migrate"'
    echo "Running post-deployment database migrations"
    su - mastodon -c '/usr/local/bin/bash -c "cd /usr/local/www/mastodon; RAILS_ENV=production SAFETY_ASSURED=1 /usr/local/bin/bundle exec rails db:migrate"'
fi

# precompile assets
# todo: we only want to do this if it hasn't already been done!
echo "Precompiling assets as mastodon user"
su - mastodon -c '/usr/local/bin/bash -c "cd /usr/local/www/mastodon; RAILS_ENV=production /usr/local/bin/bundle exec rails assets:precompile"'

# set back this
set -e
# shellcheck disable=SC3040
set -o pipefail

# copy over RC scripts and set executable permissions
echo "Copying over RC scripts"
cp -f "$TEMPLATEPATH/rc.mastodon_sidekiq.in" /usr/local/etc/rc.d/mastodon_sidekiq
chmod +x /usr/local/etc/rc.d/mastodon_sidekiq

cp -f "$TEMPLATEPATH/rc.mastodon_streaming.in" /usr/local/etc/rc.d/mastodon_streaming
chmod +x /usr/local/etc/rc.d/mastodon_streaming

cp -f "$TEMPLATEPATH/rc.mastodon_web.in" /usr/local/etc/rc.d/mastodon_web
chmod +x /usr/local/etc/rc.d/mastodon_web

# enable services
echo "Enabling mastodon services"
service mastodon_sidekiq enable || true
service mastodon_streaming enable || true
service mastodon_web enable || true

# to-do
# add crontab entries
# bundle exec rake mastodon:media:remove_remote