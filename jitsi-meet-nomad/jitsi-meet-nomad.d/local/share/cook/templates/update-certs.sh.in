#!/usr/local/bin/bash

mydomain="%%domain%%"
registermail="%%email%%"

if [ -d "/mnt/acme/$mydomain" ]; then
    mv "/mnt/acme/$mydomain" "/mnt/acme/$mydomain.old"
    /usr/local/sbin/acme.sh --register-account -m "$registermail" --home /mnt/acme --server letsencrypt
    /usr/local/sbin/acme.sh --issue -d "$mydomain" --home /mnt/acme --standalone
    cd "/mnt/acme/$mydomain/"
    cp -f * /usr/local/etc/ssl/
    service nginx restart
    exit 0
else
    echo "There is no /mnt/acme/$mydomain directory"
    exit 1
fi
