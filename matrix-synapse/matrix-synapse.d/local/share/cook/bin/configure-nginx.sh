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

# copy in custom nginx and set IP to ip address of pot image
< "$TEMPLATEPATH/nginx.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# copy in certrenew script
mkdir -p /root/bin
< "$TEMPLATEPATH/certrenew.sh.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /root/bin/certrenew.sh

# set executable permissions
chmod u+x /root/bin/certrenew.sh

# setup crontab
echo "30      4       1       *       *       root   /bin/sh /root/bin/certrenew.sh" >> /etc/crontab

# certificates
echo "Generating certificates"
# the following is required for option --set-default-ca
mkdir -p /mnt/acme
mkdir -p /root/.acme.sh/
touch /root/.acme.sh/account.conf

if [ ! -d /mnt/acme/"$DOMAIN"_ecc ]; then
    /usr/local/sbin/acme.sh --register-account -m "$SSLEMAIL" --home /mnt/acme --server zerossl
    /usr/local/sbin/acme.sh --set-default-ca --server zerossl
    /usr/local/sbin/acme.sh --issue -d "$DOMAIN" --server zerossl \
      --home /mnt/acme --standalone --listen-v4 --httpport 80 --log /mnt/acme/acme.sh.log || true
    if [ ! -f /mnt/acme/"$DOMAIN"_ecc/"$DOMAIN".cer ]; then
        echo "Trying to register cert again, sleeping 30"
        sleep 30
        /usr/local/sbin/acme.sh --issue -d "$DOMAIN" --server zerossl \
          --home /mnt/acme --standalone --listen-v4 --httpport 80 --log /mnt/acme/acme.sh.log || true
        if [ ! -f /mnt/acme/"$DOMAIN"_ecc/"$DOMAIN".cer ]; then
            echo "missing $DOMAIN.cer, certificate not registered"
            exit 1
        fi
    fi
    # copy files to ssl dir
    cp -Rf /mnt/acme/"$DOMAIN"_ecc/ /usr/local/etc/ssl/
else
    echo "/mnt/acme/$DOMAIN\_ecc exists, not creating certificates, copying to SSL dir"
    # try continue, with a cert hopefully
    cp -Rf /mnt/acme/"$DOMAIN"_ecc/ /usr/local/etc/ssl/
fi

# enable nginx
if [ -f "/usr/local/etc/ssl/${DOMAIN}.key" ]; then
    service nginx enable || true
else
    echo "Cannot enable nginx. Missing /usr/local/etc/ssl/${DOMAIN}.key"
    exit 1
fi
