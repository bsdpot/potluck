#!/bin/sh

# Based on POTLUCK TEMPLATE v3.0
# Altered by Michael Gmelin
#
# EDIT THE FOLLOWING FOR NEW FLAVOUR:
# 1. RUNS_IN_NOMAD - true or false
# 2. If RUNS_IN_NOMAD is false, can delete the <flavour>+4 file, else
#    make sure pot create command doesn't include it
# 3. Create a matching <flavour> file with this <flavour>.sh file that
#    contains the copy-in commands for the config files from <flavour>.d/
#    Remember that the package directories don't exist yet, so likely copy
#    to /root
# 4. Adjust package installation between BEGIN & END PACKAGE SETUP
# 5. Adjust jail configuration script generation between BEGIN & END COOK
#    Configure the config files that have been copied in where necessary

# Set this to true if this jail flavour is to be created as a nomad (i.e. blocking) jail.
# You can then query it in the cook script generation below and the script is installed
# appropriately at the end of this script
RUNS_IN_NOMAD=true

# set the cook log path/filename
COOKLOG=/var/log/cook.log

# check if cooklog exists, create it if not
if [ ! -e $COOKLOG ]
then
    echo "Creating $COOKLOG" | tee -a $COOKLOG
else
    echo "WARNING $COOKLOG already exists"  | tee -a $COOKLOG
fi
date >> $COOKLOG

# -------------------- COMMON ---------------

STEPCOUNT=0
step() {
  STEPCOUNT=$(("$STEPCOUNT" + 1))
  STEP="$*"
  echo "Step $STEPCOUNT: $STEP" | tee -a $COOKLOG
}

exit_ok() {
  trap - EXIT
  exit 0
}

FAILED=" failed"
exit_error() {
  STEP="$*"
  FAILED=""
  exit 1
}

set -e
trap 'echo ERROR: $STEP$FAILED | (>&2 tee -a $COOKLOG)' EXIT

# -------------- BEGIN PACKAGE SETUP -------------
step "Bootstrap package repo"
mkdir -p /usr/local/etc/pkg/repos
# shellcheck disable=SC2016
#echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' \
echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/quarterly" }' \
  >/usr/local/etc/pkg/repos/FreeBSD.conf
ASSUME_ALWAYS_YES=yes pkg bootstrap

step "Touch /etc/rc.conf"
touch /etc/rc.conf

# this is important, otherwise running /etc/rc from cook will
# overwrite the IP address set in tinirc
step "Remove ifconfig_epair0b from config"
# shellcheck disable=SC2015
sysrc -cq ifconfig_epair0b && sysrc -x ifconfig_epair0b || true

step "Disable sendmail"
service sendmail onedisable

# optionally disable ssh access
step "Disable sshd"
service sshd onedisable || true

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

step "Install package nginx"
pkg install -y nginx

step "Install package mariadb105-client"
pkg install -y mariadb105-client

step "Install package postgresql13-client"
pkg install -y postgresql13-client

step "Install package memcached"
pkg install -y memcached

step "Install package fontconfig"
pkg install -y fontconfig

step "Install package freetype2"
pkg install -y freetype2

step "Install package giflib"
pkg install -y giflib

step "Install package gmp"
pkg install -y gmp

step "Install package icu"
pkg install -y icu

step "Install package jbigkit"
pkg install -y jbigkit

step "Install package jpeg-turbo"
pkg install -y jpeg-turbo

step "Install package libargon2"
pkg install -y libargon2

step "Install package libgcrypt"
pkg install -y libgcrypt

step "Install package libgd"
pkg install -y libgd

step "Install package libgpg-error"
pkg install -y libgpg-error

step "Install package libxslt"
pkg install -y libxslt

step "Install package libzip"
pkg install -y libzip

step "Install package oniguruma"
pkg install -y oniguruma

step "Install package openldap24-client"
pkg install -y openldap24-client

step "Install package png"
pkg install -y png

step "Install package tiff"
pkg install -y tiff

step "Install package webp"
pkg install -y webp

step "Install package pkgconf"
pkg install -y pkgconf

step "Install package php82"
pkg install -y php82

step "Install package php82-extensions"
pkg install -y php82-extensions

step "Install package php82-bcmath"
pkg install -y php82-bcmath

step "Install package php82-bz2"
pkg install -y php82-bz2

step "Install package php82-ctype"
pkg install -y php82-ctype

step "Install package php82-curl"
pkg install -y php82-curl

step "Install package php82-dom"
pkg install -y php82-dom

step "Install package php82-exif"
pkg install -y php82-exif

step "Install package php82-fileinfo"
pkg install -y php82-fileinfo

step "Install package php82-filter"
pkg install -y php82-filter

step "Install package php82-ftp"
pkg install -y php82-ftp

step "Install package php82-gd"
pkg install -y php82-gd

step "Install package php82-gmp"
pkg install -y php82-gmp

step "Install package php82-iconv"
pkg install -y php82-iconv

step "Install package php82-imap"
pkg install -y php82-imap

step "Install package php82-intl"
pkg install -y php82-intl

step "Install package php82-ldap"
pkg install -y php82-ldap

step "Install package php82-mysqli"
pkg install -y php82-mysqli

step "Install package php82-mbstring"
pkg install -y php82-mbstring

step "Install package php82-opcache"
pkg install -y php82-opcache

# doesn't exist, ssl may be integrated in core
#step "Install package php82-openssl"
#pkg install -y php82-openssl

step "Install package php82-pcntl"
pkg install -y php82-pcntl

step "Install package php82-pdo"
pkg install -y php82-pdo

step "Install package php82-pdo_mysql"
pkg install -y php82-pdo_mysql

step "Install package php82-pecl-APCu"
pkg install -y php82-pecl-APCu

step "Install package php82-pecl-memcached"
pkg install -y php82-pecl-memcached

step "Install package php82-pecl-redis"
pkg install -y php82-pecl-redis

step "Install package php82-pecl-imagick"
pkg install -y php82-pecl-imagick

step "Install package php82-phar"
pkg install -y php82-phar

step "Install package php82-posix"
pkg install -y php82-posix

step "Install package php82-session"
pkg install -y php82-session

step "Install package php82-simplexml"
pkg install -y php82-simplexml

step "Install package php82-xml"
pkg install -y php82-xml

step "Install package php82-xmlreader"
pkg install -y php82-xmlreader

step "Install package php82-xmlwriter"
pkg install -y php82-xmlwriter

step "Install package php82-xsl"
pkg install -y php82-xsl

step "Install package php82-zip"
pkg install -y php82-zip

step "Install package php82-zlib"
pkg install -y php82-zlib

step "Install package ImageMagick6-nox11"
pkg install -y ImageMagick6-nox11

step "Install package libheif"
pkg install -y libheif

step "Install package ffmpeg"
pkg install -y ffmpeg

step "Install package jq"
pkg install -y jq

step "Install package nano"
pkg install -y nano

step "Install package sudo"
pkg install -y sudo

pkg clean -y

step "Create necessary directories if they don't exist"
# Create mountpoints
mkdir /.snapshots

step "Enable nginx"
service nginx enable

step "Enable php-fpm"
#sysrc php_fpm_enable="YES"
service php-fpm enable

# ---------- END PACKAGE & MOUNTPOINT SETUP -------------

#
# Create configurations
#

#
# Now generate the run command script "cook"
# It configures the system on the first run by creating the config file(s)
# On subsequent runs, it only starts sleeps (if nomad-jail) or simply exits
#

# clear any old cook runtime file
step "Clean cook artifacts"
rm -rf /usr/local/bin/cook

# ----------------- BEGIN COOK ------------------
step "Create cook script"
echo "#!/bin/sh
RUNS_IN_NOMAD=$RUNS_IN_NOMAD
# declare this again for the pot image, might work carrying variable through like
# with above
COOKLOG=/var/log/cook.log

# No need to change this, just ensures configuration is done only once
if [ -e /usr/local/etc/pot-is-seasoned ]
then
    # If this pot flavour is blocking (i.e. it should not return),
    # we block indefinitely
    if [ \"\$RUNS_IN_NOMAD\" = \"true\" ]
    then
        /bin/sh /etc/rc
        tail -f /dev/null
    fi
    exit 0
fi

# ADJUST THIS: STOP SERVICES AS NEEDED BEFORE CONFIGURATION
service nginx onestop || true
service php-fpm onestop || true

# No need to adjust this:
# If this pot flavour is not blocking, we need to read the environment first from /tmp/environment.sh
# where pot is storing it in this case
if [ -e /tmp/environment.sh ]
then
    . /tmp/environment.sh
fi

#
# ADJUST THIS BY CHECKING FOR ALL VARIABLES YOUR FLAVOUR NEEDS:
#

# Convert parameters to variables if passed (overwrite environment)
while getopts d:s: option
do
    case \"\${option}\"
    in
      d) DATADIR=\${OPTARG};;
      s) SELFSIGNHOST=\${OPTARG};;
    esac
done

# Check config variables are set
if [ -z \${DATADIR+x} ];
then
    echo 'DATADIR is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'DATADIR is unset - see documentation how to configure this flavour'
    DATADIR=\"/usr/local/www/nextcloud/data\"
fi
if [ -z \${SELFSIGNHOST+x} ];
then
    echo 'SELFSIGNHOST is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'SELFSIGNHOST is unset - see documentation how to configure this flavour'
    SELFSIGNHOST=\"none\"
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE ADJUSTED & COPIED:

# If we do not find a Nextcloud installation, we install it. If we do find something though,
# we do not install/overwrite anything as we assume that updates/modifications are happening
# from within the Nextcloud installation, we install it. If we do find something though,
# we do not install/overwrite anything as we assume that updates/modifications are happening
# from within Nextcloud.
if [ ! -e /usr/local/www/nextcloud/status.php ]; then
    pkg install -y nextcloud-php82 nextcloud-twofactor_totp-php82 nextcloud-deck-php82 nextcloud-mail-php82 nextcloud-contacts-php82 nextcloud-calendar-php82 nextcloud-end_to_end_encryption-php82
fi

# Configure PHP FPM
sed -i .orig 's|listen = 127.0.0.1:9000|listen = /var/run/php82-fpm.sock|g' /usr/local/etc/php-fpm.d/www.conf
sed -i .orig 's|pm.max_children = 5|pm.max_children = 10|g' /usr/local/etc/php-fpm.d/www.conf
echo \";Nomad Nextcloud settings...\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"listen.owner = www\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"listen.group = www\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"listen.mode = 0660\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"env[PATH] = /usr/local/bin:/usr/bin:/bin\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"env[TMP] = /tmp\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"env[TMPDIR] = /tmp\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"env[TEMP] = /tmp\" >> /usr/local/etc/php-fpm.d/www.conf

# Configure PHP
cp -f /usr/local/etc/php.ini-production /usr/local/etc/php.ini
cp -f /root/99-custom.ini /usr/local/etc/php/99-custom.ini

# check for presence of copied-in /root/nc-config.php and copy over any existing (with backup)
if [ -s /root/nc-config.php ]; then
    if [ -s /usr/local/www/nextcloud/config/config.php ]; then
        cp -f /usr/local/www/nextcloud/config/config.php /usr/local/www/nextcloud/config/config.php.old
    fi
    cp -f /root/nc-config.php /usr/local/www/nextcloud/config/config.php
fi

# Fix www group memberships so it works with fuse mounted directories
pw addgroup -n newwww -g 1001
pw moduser www -u 1001 -G 80,0,1001

# set perms on /usr/local/www/nextcloud/*
chown -R www:www /usr/local/www/nextcloud

# create a nextcloud log file
# this needs to be configured in nextcloud config.php in copy-in file
touch /var/log/nginx/nextcloud.log
chown www:www /var/log/nginx/nextcloud.log

# manually create php log and set owner
touch /var/log/nginx/php.scripts.log
chown www:www /var/log/nginx/php.scripts.log

# check for .ocdata in DATADIR
# if using S3 with no mount-in this should set it up in the default DATADIR
# /usr/local/nginx/nextcloud/data
if [ ! -f \"\${DATADIR}\"/.ocdata ]; then
   touch\"\${DATADIR}\"/.ocdata
   chown www:www \"\${DATADIR}\"/.ocdata
fi

# set perms on DATADIR
chown -R www:www \"\${DATADIR}\"

# configure self-signed certificates for libcurl, mostly used for minio with self-signed certificates
# nextcloud source needs patching to work with self-signed certificates too
if [ \"\${SELFSIGNHOST}\" != \"none\" ]; then
    echo \"\" | /usr/bin/openssl s_client -showcerts -connect \"\${SELFSIGNHOST}\" |/usr/bin/openssl x509 -outform PEM > /tmp/cert.pem
    if [ -f /tmp/cert.pem ]; then
        cat /tmp/cert.pem >> /usr/local/share/certs/ca-root-nss.crt
        echo \"openssl.cafile=/usr/local/share/certs/ca-root-nss.crt\" >> /usr/local/etc/php/99-custom.ini
        cat /tmp/cert.pem >> /usr/local/www/nextcloud/resources/config/ca-bundle.crt
    fi
    # Patch nextcloud source for self-signed certificates with S3
    if [ -f /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php ] && [ -f /root/S3ObjectTrait.patch ]; then
        # make sure we haven't already applied the patch
        checknotapplied=\$(grep -c verify_peer_name /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php)
        if [ \"\${checknotapplied}\" -eq 0 ]; then
            # check the patch will apply cleanly
            testpatch=\$(patch --check -i /root/S3ObjectTrait.patch /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php | echo \"\$?\")
            if [ \"\${testpatch}\" -eq 0 ]; then
                # apply the patch
                patch -i /root/S3ObjectTrait.patch /usr/local/www/nextcloud/lib/private/Files/ObjectStore/S3ObjectTrait.php
            fi
        fi
    fi
fi

# Configure NGINX
cp -f /root/nginx.conf /usr/local/etc/nginx/nginx.conf

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# we need to kill nginx then start it
killall -9 nginx
kill -9 \$(/bin/pgrep nginx)

# restart services

#service php-fpm restart
timeout --foreground 120 \
  sh -c 'while ! service php-fpm status; do
    service php-fpm start || true; sleep 5;
  done'

#service nginx restart
timeout --foreground 120 \
  sh -c 'while ! service nginx status; do
    service nginx start || true; sleep 5;
  done'

# setup cronjob
echo \"*/15  *  *  *  *  www  /usr/local/bin/php -f /usr/local/www/nextcloud/cron.php\" >> /etc/crontab

# Do not touch this:
touch /usr/local/etc/pot-is-seasoned

# If this pot flavour is blocking (i.e. it should not return), there is no /tmp/environment.sh
# created by pot and we now after configuration block indefinitely
if [ \"\$RUNS_IN_NOMAD\" = \"true\" ]
then
    /bin/sh /etc/rc
    tail -f /dev/null
fi
" > /usr/local/bin/cook


# ----------------- END COOK ------------------


# ---------- NO NEED TO EDIT BELOW ------------

step "Make cook script executable"
if [ -e /usr/local/bin/cook ]
then
    echo "setting executable bit on /usr/local/bin/cook" | tee -a $COOKLOG
    chmod u+x /usr/local/bin/cook
else
    exit_error "there is no /usr/local/bin/cook to make executable"
fi

#
# There are two ways of running a pot jail: "Normal", non-blocking mode and
# "Nomad", i.e. blocking mode (the pot start command does not return until
# the jail is stopped).
# For the normal mode, we create a /usr/local/etc/rc.d script that starts
# the "cook" script generated above each time, for the "Nomad" mode, the cook
# script is started by pot (configuration through flavour file), therefore
# we do not need to do anything here.
#

# Create rc.d script for "normal" mode:
step "Create rc.d script to start cook"
echo "creating rc.d script to start cook" | tee -a $COOKLOG

# shellcheck disable=SC2016
echo '#!/bin/sh
#
# PROVIDE: cook
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
. /etc/rc.subr
name="cook"
rcvar="cook_enable"
load_rc_config $name
: ${cook_enable:="NO"}
: ${cook_env:=""}
command="/usr/local/bin/cook"
command_args=""
run_rc_command "$1"
' > /usr/local/etc/rc.d/cook

step "Make rc.d script to start cook executable"
if [ -e /usr/local/etc/rc.d/cook ]
then
  echo "Setting executable bit on cook rc file" | tee -a $COOKLOG
  chmod u+x /usr/local/etc/rc.d/cook
else
  exit_error "/usr/local/etc/rc.d/cook does not exist"
fi

if [ "$RUNS_IN_NOMAD" != "true" ]
then
  step "Enable cook service"
  # This is a non-nomad (non-blocking) jail, so we need to make sure the script
  # gets started when the jail is started:
  # Otherwise, /usr/local/bin/cook will be set as start script by the pot flavour
  echo "enabling cook" | tee -a $COOKLOG
  service cook enable
fi

# -------------------- DONE ---------------
exit_ok
