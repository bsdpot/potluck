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

## commenting out, seems to be breaking stuff, and fuse mounts not in use ##
# Fix www group memberships so it works with fuse mounted directories
#groupcheck=$(grep -c newwww /etc/group)
#if [ "${groupcheck}" -eq 0 ]; then
#    pw addgroup -n newwww -g 1001
#    pw moduser www -u 1001 -G 80,0,1001
#fi

# set perms on /usr/local/www/nextcloud/*
chown -R www:www /usr/local/www/nextcloud

# create a nextcloud log file
# this needs to be configured in nextcloud config.php in copy-in file
if [ -d /var/log/nginx ]; then
    touch /var/log/nginx/nextcloud.log
    chown www:www /var/log/nginx/nextcloud.log
fi

# check for .ocdata in DATADIR
# if using S3 with no mount-in this should set it up in the default DATADIR
# /usr/local/nginx/nextcloud/data
if [ ! -f "${DATADIR}/.ocdata" ]; then
   touch "${DATADIR}/.ocdata"
   chown www:www "${DATADIR}/.ocdata"
fi

# set perms on DATADIR
chown -R www:www "${DATADIR}"

# mkdir and copy over the postinstall.sh script to /root/bin
mkdir -p /root/bin
cp -f "$TEMPLATEPATH/postinstall.sh.in" /root/bin/postinstall.sh
chmod +x /root/bin/postinstall.sh

# configure self-signed certificates for libcurl, mostly used for minio with self-signed certificates
# nextcloud source needs patching to work with self-signed certificates too
if [ -n "${SELFSIGNHOST}" ]; then
    # append the copied in rootca file to necessary files
    if [ -f /root/rootca.crt ]; then
        cat /root/rootca.crt >> /usr/local/share/certs/ca-root-nss.crt
        # testing making this permanent, 99-custom.ini has sections and appending no good any more
        #echo "openssl.cafile=/usr/local/share/certs/ca-root-nss.crt" >> /usr/local/etc/php/99-custom.ini
        cat /root/rootca.crt >> /usr/local/www/nextcloud/resources/config/ca-bundle.crt
    fi

    # if [ -n "${SPECIALPATCH}" ]; then
    #     # Patch nextcloud source for self-signed certificates with S3
    #     if [ -f /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php ] && [ -f "$TEMPLATEPATH/S3ObjectTrait.patch" ]; then
    #         # make sure we haven't already applied the patch
    #         checknotapplied=$(grep -c verify_peer_name /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php)
    #         if [ "${checknotapplied}" -eq 0 ]; then
    #             # check the patch will apply cleanly
    #             # shellcheck disable=SC2008
    #             testpatch=$(patch --check -i "$TEMPLATEPATH/S3ObjectTrait.patch" /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php | echo "$?")
    #             if [ "${testpatch}" -eq 0 ]; then
    #                 # apply the patch
    #                 patch -i "$TEMPLATEPATH/S3ObjectTrait.patch" /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php
    #             fi
    #         fi
    #     fi
    # else
    #     if [ -f /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php ] && [ -f "$TEMPLATEPATH/nosslverify.patch" ]; then
    #         if [ ! -f /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php.patched ]; then
    #             cp "$TEMPLATEPATH/nosslverify.patch" /usr/local/www/nextcloud/lib/private/Files/ObjectStore/nosslverify.patch
    #             sed -e "/'cafile' => \$bundle/r /usr/local/www/nextcloud/lib/private/Files/ObjectStore/nosslverify.patch" -e "//d" /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php > /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php.patched
    #             cp -f /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php.original
    #             cp -f /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php.patched /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php
    #         fi
    #     fi
    # fi
fi
