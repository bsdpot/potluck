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

# Set this to true if this jail flavour is to be created as a nomad
# (i.e. blocking) jail.
# You can then query it in the cook script generation below and the script
# is installed appropriately at the end of this script
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
# only modify repo if not already done in base image
# shellcheck disable=SC2016
test -e /usr/local/etc/pkg/repos/FreeBSD.conf || \
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
service sendmail onedisable || true

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

step "Install package openldap26-client"
pkg install -y openldap26-client

step "Install package png"
pkg install -y png

step "Install package tiff"
pkg install -y tiff

step "Install package webp"
pkg install -y webp

step "Install package pkgconf"
pkg install -y pkgconf

step "Install package php81"
pkg install -y php81

step "Install package php81-extensions"
pkg install -y php81-extensions

step "Install package php81-bcmath"
pkg install -y php81-bcmath

step "Install package php81-bz2"
pkg install -y php81-bz2

step "Install package php81-ctype"
pkg install -y php81-ctype

step "Install package php81-curl"
pkg install -y php81-curl

step "Install package php81-dom"
pkg install -y php81-dom

step "Install package php81-exif"
pkg install -y php81-exif

step "Install package php81-fileinfo"
pkg install -y php81-fileinfo

step "Install package php81-filter"
pkg install -y php81-filter

step "Install package php81-ftp"
pkg install -y php81-ftp

step "Install package php81-gd"
pkg install -y php81-gd

step "Install package php81-gmp"
pkg install -y php81-gmp

step "Install package php81-iconv"
pkg install -y php81-iconv

step "Install package php81-imap"
pkg install -y php81-imap

step "Install package php81-intl"
pkg install -y php81-intl

step "Install package php81-ldap"
pkg install -y php81-ldap

step "Install package php81-mysqli"
pkg install -y php81-mysqli

step "Install package php81-mbstring"
pkg install -y php81-mbstring

step "Install package php81-opcache"
pkg install -y php81-opcache

step "Install package php81-pcntl"
pkg install -y php81-pcntl

step "Install package php81-pdo"
pkg install -y php81-pdo

step "Install package php81-pdo_mysql"
pkg install -y php81-pdo_mysql

step "Install package php81-pecl-APCu"
pkg install -y php81-pecl-APCu

step "Install package php81-pecl-memcached"
pkg install -y php81-pecl-memcached

step "Install package php81-pecl-redis"
pkg install -y php81-pecl-redis

step "Install package php81-pecl-imagick"
pkg install -y php81-pecl-imagick

step "Install package php81-phar"
pkg install -y php81-phar

step "Install package php81-posix"
pkg install -y php81-posix

step "Install package php81-session"
pkg install -y php81-session

step "Install package php81-simplexml"
pkg install -y php81-simplexml

step "Install package php81-xml"
pkg install -y php81-xml

step "Install package php81-xmlreader"
pkg install -y php81-xmlreader

step "Install package php81-xmlwriter"
pkg install -y php81-xmlwriter

step "Install package php81-xsl"
pkg install -y php81-xsl

step "Install package php81-zip"
pkg install -y php81-zip

step "Install package php81-zlib"
pkg install -y php81-zlib

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

step "Clean package installation"
pkg clean -y

step "Create necessary directories if they don't exist"
# Create mountpoints
mkdir /.snapshots

step "Enable nginx"
service nginx enable

step "Enable php-fpm"
service php-fpm enable

# -------------- END PACKAGE SETUP -------------

#
# Now generate the run command script "cook"
# It configures the system on the first run by creating the config file(s)
# On subsequent runs, it only starts sleeps (if nomad-jail) or simply exits
#

# this runs when image boots
# ----------------- BEGIN COOK ------------------

step "Clean cook artifacts"
rm -rf /usr/local/bin/cook /usr/local/share/cook

step "Install pot local"
tar -C /root/.pot_local -cf - . | tar -C /usr/local -xf -
rm -rf /root/.pot_local

step "Set file ownership on cook scripts"
chown -R root:wheel /usr/local/bin/cook /usr/local/share/cook
chmod 755 /usr/local/share/cook/bin/*

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
  # Otherwise, /usr/local/bin/cook will be set as start script by the pot
  # flavour
  echo "enabling cook" | tee -a $COOKLOG
  service cook enable
fi

# -------------------- DONE ---------------
exit_ok
