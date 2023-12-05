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

# create mastodon user without -m, --create-home
if ! id -u "mastodon" >/dev/null 2>&1; then
  /usr/sbin/pw useradd -n mastodon -c 'Mastodon User' -d /usr/local/www/mastodon -s /bin/sh -h -
fi

# make directory to store keys
mkdir -p /mnt/mastodon/private

# set permissions on key directory after creating user
chown -R mastodon:mastodon /mnt/mastodon/

# make sure we have /usr/local/www/mastodon
mkdir -p /usr/local/www/mastodon

# set perms on /usr/local/www/mastodon to mastodon:mastodon
chown -R mastodon:mastodon /usr/local/www/mastodon

# move this up
SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

# if we do not have /usr/local/www/mastodon/.git then
# configure /usr/local/www/mastodon as git repo and pull files
if [ ! -d /usr/local/www/mastodon/.git ]; then
	echo "Initiating git repo in /usr/local/www/mastodon"
	su - mastodon -c "cd /usr/local/www/mastodon; git init"
	#echo "Adding remote origin https://github.com/mastodon/mastodon.git"
	#su - mastodon -c "cd /usr/local/www/mastodon; git remote add origin https://github.com/mastodon/mastodon.git"
	#switch to fork with 5k post limit
	echo "Adding remote origin https://github.com/woganmay/mastodon.git"
	su - mastodon -c "cd /usr/local/www/mastodon; git remote add origin https://github.com/woganmay/mastodon.git"
	echo "Running git fetch"
	su - mastodon -c "cd /usr/local/www/mastodon; git fetch"
	echo "Checking out the mastodon release we want"
	su - mastodon -c "cd /usr/local/www/mastodon; git checkout v4.2.1-patch"
else
	echo ".git directory exists, not cloning repo"
fi

# moved from base file mastodon-s3.sh in anticipation switch to install from github
#
# The FreeBSD wiki has a set of instructions
# https://wiki.freebsd.org/Ports/net-im/mastodon
# however it is missing a step to 'yarn add node-gyp'
# as covered in the Bastillefile at
# https://codeberg.org/ddowse/mastodon/src/branch/main/Bastillefile

# Update Gemfile for older version json-canonicalization
cp -f "$TEMPLATEPATH/Gemfile.lock.in" /usr/local/www/mastodon/Gemfile.lock
chown  mastodon:mastodon /usr/local/www/mastodon/Gemfile.lock

# enable corepack
echo "Enabling corepack"
/usr/local/bin/corepack enable

# Add node-gyp to yarn
echo "Adding node-gyp to yarn"
/usr/local/bin/yarn add node-gyp

# as user mastodon - set yarn classic
# enable this for wogan fork
echo "Setting yarn to classic version"
su - mastodon -c "/usr/local/bin/yarn set version classic"
# undo this for wogan fork
#echo "Setting yarn to stable version"
#su - mastodon -c "/usr/local/bin/yarn set version stable"

# as user mastodon - enable deployment
echo "Setting mastodon deployment to true"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle config deployment 'true'"

# as user mastodon - remove development and test environments
echo "Removing development and test environments"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle config without 'development test'"

# as user mastodon - bundle install
echo "Installing the required files with bundle"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle install -j1"

# add babel-plugin-lodash@3.3.4 compression-webpack-plugin@6.1.1
# this is a temp fix for the error about missing versions
# "Using --ignore-workspace-root-check or -W allows a package to be installed at the workspaces root.
# This tends not to be desired behaviour, as dependencies are generally expected to be part of a workspace."
# disable for wogan fork, testing
#echo "Adding yarn package dependancies - temp fix"
## no -W with yarn stable aka version 4+
##su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/yarn add babel-plugin-lodash@3.3.4 compression-webpack-plugin@10.0.0 -W"

# as user mastodon - yarn install process
echo "Installing the required files with yarn"
# enable for wogan fork
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/yarn install --pure-lockfile"
# disable for wogan fork
#su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/yarn install --immutable"

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
  sed "s${sep}%%aliashost%%${sep}$BUCKETALIAS${sep}g" \
  > /usr/local/www/mastodon/.env.production

# set permissions on the file
echo "Setting permissions on env file"
chown mastodon:mastodon /usr/local/www/mastodon/.env.production

# copy in upgrade script to /root/upgrade-mastodon.sh
< "$TEMPLATEPATH/upgrade-mastodon.sh.in" \
  sed "s${sep}%%redishost%%${sep}$REDISHOST${sep}g" | \
  sed "s${sep}%%dbuser%%${sep}$DBUSER${sep}g" | \
  sed "s${sep}%%dbpass%%${sep}$DBPASS${sep}g" | \
  sed "s${sep}%%dbhost%%${sep}$DBHOST${sep}g" | \
  sed "s${sep}%%dbport%%${sep}$SETDBPORT${sep}g" | \
  sed "s${sep}%%dbname%%${sep}$DBNAME${sep}g" \
  > /root/upgrade-mastodon.sh

# set permissions on upgrade script
chmod 750 /root/upgrade-mastodon.sh

# remote command database check
# with bash we can set the shell variable PGPASSWORD="$DBPASS" and run psql without
# being asked for a password.
# with csh we must use the connect string and query postgres db
echo "Checking remote database access"

# unset this
set +e
# shellcheck disable=SC3040
set +o pipefail

dbcheck=$(/usr/local/bin/psql "postgresql://$DBUSER:$DBPASS@$DBHOST:$DBPORT/postgres" -lqt | grep -c "$DBNAME")
if [ "$dbcheck" -eq "0" ]; then
	echo "Setting up a new database"
	su - mastodon -c '/usr/local/bin/bash -c "cd /usr/local/www/mastodon; RAILS_ENV=production SAFETY_ASSURED=1 /usr/local/bin/bundle exec rails db:setup"'
else
	echo "Database $DBNAME already exists on $DBHOST, no need to create it."
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