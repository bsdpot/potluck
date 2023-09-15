#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# make directory to store keys
mkdir -p /mnt/mastodon/private
chown -R mastodon:mastodon /mnt/mastodon/

# generate a rake secret if the file /mnt/mastodon/private/secret.key doesn't exist
if [ -f /mnt/mastodon/private/secret.key ]; then
	SECRETKEY=$(cat /mnt/mastodon/private/secret.key)
else
	echo "Creating a secret key"
	su - mastodon -c 'cd /usr/local/www/mastodon && /usr/local/bin/bundle exec rake secret -e RAILS_ENV=production > /mnt/mastodon/private/secret.key'
	SECRETKEY=$(cat /mnt/mastodon/private/secret.key)
fi

# generate OTP secret if the file /mnt/mastodon/private/otp.key doesn't exist
if [ -f /mnt/mastodon/private/otp.key ]; then
	OTPSECRET=$(cat /mnt/mastodon/private/otp.key)
else
	echo "Creating OTP key"
	su - mastodon -c 'cd /usr/local/www/mastodon && /usr/local/bin/bundle exec rake secret -e RAILS_ENV=production > /mnt/mastodon/private/otp.key'
	OTPSECRET=$(cat /mnt/mastodon/private/otp.key)
fi

# generate vapid keys if the file /mnt/mastodon/private/vapid.keys doesn't exist
if [ -f /mnt/mastodon/private/vapid.keys ]; then
	VAPIDPRIVATEKEY=$(grep VAPID_PRIVATE_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
	VAPIDPUBLICKEY=$(grep VAPID_PUBLIC_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
else
	echo "Creating Vapid keys"
	su - mastodon -c 'cd /usr/local/www/mastodon && /usr/local/bin/bundle exec rake mastodon:webpush:generate_vapid_key -e RAILS_ENV=production > /mnt/mastodon/private/vapid.keys'
	VAPIDPRIVATEKEY=$(grep VAPID_PRIVATE_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
	VAPIDPUBLICKEY=$(grep VAPID_PUBLIC_KEY /mnt/mastodon/private/vapid.keys | awk -F'=' '{print $2}')
fi

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

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
  sed "s${sep}%%s3user%%${sep}$BUCKETUSER${sep}g" | \
  sed "s${sep}%%s3pass%%${sep}$BUCKETPASS${sep}g" | \
  sed "s${sep}%%region%%${sep}$BUCKETREGION${sep}g" | \
  sed "s${sep}%%aliashost%%${sep}$BUCKETALIAS${sep}g" \
  > /usr/local/www/mastodon/.env.production

# set permissions on the file
chown mastodon:mastodon /usr/local/www/mastodon/.env.production

# setup database
su - mastodon -c 'cd /usr/local/www/mastodon && /usr/local/bin/bundle exec rails db:setup -e SAFETY_ASSURED=1 -e RAILS_ENV=production'

# precompile assets
su - mastodon -c 'cd /usr/local/www/mastodon && /usr/local/bin/bundle exec rails assets:precompile'

# enable services
service mastodon_sidekiq enable
service mastodon_streaming enable
service mastodon_web enable

# to-do
# add crontab entries
# bundle exec rake mastodon:media:remove_remote