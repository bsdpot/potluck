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

# copy in custom nginx and set IP to ip address of pot image
< "$TEMPLATEPATH/nginx.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# copy in certrenew script
< "$TEMPLATEPATH/certrenew.sh.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /root/certrenew.sh

# set executable permissions
chmod u+x /root/certrenew.sh

# setup crontab
echo "30      4       1       *       *       root   /bin/sh /root/certrenew.sh" >> /etc/crontab

# certificates
echo "Generating certificates"
cd /root
/usr/local/sbin/acme.sh --register-account -m "${SSLEMAIL}" --server zerossl
/usr/local/sbin/acme.sh --force --issue -d "${DOMAIN}" --standalone
cp -f /.acme.sh/"${DOMAIN}"/* /usr/local/etc/ssl/

# enable nginx
if [ -f "/usr/local/etc/ssl/${DOMAIN}.key" ]; then
    service nginx enable || true
else
    echo "Cannot enable nginx. Missing /usr/local/etc/ssl/${DOMAIN}.key"
    exit 1
fi
