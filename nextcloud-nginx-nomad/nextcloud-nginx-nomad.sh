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
# shellcheck disable=SC2016
echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' \
    >/usr/local/etc/pkg/repos/FreeBSD.conf
# remove above and add back below for quarterlies
# only modify repo if not already done in base image
#test -e /usr/local/etc/pkg/repos/FreeBSD.conf || \
#  echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/quarterly" }' \
#    >/usr/local/etc/pkg/repos/FreeBSD.conf
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

step "Clean freebsd-update"
rm -rf /var/db/freebsd-update
mkdir -p /var/db/freebsd-update

##############
# non-layered image additions
#############
step "Install package openssl"
pkg install -y openssl

# necessary if installing curl now
step "Install package ca_root_nss"
pkg install -y ca_root_nss

step "Install package curl"
pkg install -y curl

step "Install package jo"
pkg install -y jo

step "Install package bash"
pkg install -y bash

step "Install package rsync"
pkg install -y rsync

step "Install package nginx"
pkg install -y nginx

step "Install package caddy"
pkg install -y caddy

step "Install package mariadb106-client"
pkg install -y mariadb106-client

step "Install package postgresql15-client"
pkg install -y postgresql15-client

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

step "Install package php83"
pkg install -y php83

step "Install package php83-extensions"
pkg install -y php83-extensions

step "Install package php83-bcmath"
pkg install -y php83-bcmath

step "Install package php83-bz2"
pkg install -y php83-bz2

step "Install package php83-ctype"
pkg install -y php83-ctype

step "Install package php83-curl"
pkg install -y php83-curl

step "Install package php83-dom"
pkg install -y php83-dom

step "Install package php83-exif"
pkg install -y php83-exif

step "Install package php83-fileinfo"
pkg install -y php83-fileinfo

step "Install package php83-filter"
pkg install -y php83-filter

step "Install package php83-ftp"
pkg install -y php83-ftp

step "Install package php83-gd"
pkg install -y php83-gd

step "Install package php83-gmp"
pkg install -y php83-gmp

step "Install package php83-iconv"
pkg install -y php83-iconv

step "Install package php83-imap"
pkg install -y php83-imap

step "Install package php83-intl"
pkg install -y php83-intl

step "Install package php83-ldap"
pkg install -y php83-ldap

step "Install package php83-mysqli"
pkg install -y php83-mysqli

step "Install package php83-mbstring"
pkg install -y php83-mbstring

step "Install package php83-opcache"
pkg install -y php83-opcache

step "Install package php83-pcntl"
pkg install -y php83-pcntl

step "Install package php83-pdo"
pkg install -y php83-pdo

step "Install package php83-pdo_mysql"
pkg install -y php83-pdo_mysql

step "Install package php83-pecl-APCu"
pkg install -y php83-pecl-APCu

step "Install package php83-pecl-memcache"
pkg install -y php83-pecl-memcache

step "Install package php83-pecl-redis"
pkg install -y php83-pecl-redis

# this is giving problems Dec 2023, missing in package sources
step "Install package php83-pecl-imagick"
pkg install -y php83-pecl-imagick

step "Install package php83-pgsql"
pkg install -y php83-pgsql

step "Install package php83-pdo_pgsql"
pkg install -y php83-pdo_pgsql

step "Install package php83-phar"
pkg install -y php83-phar

step "Install package php83-posix"
pkg install -y php83-posix

step "Install package php83-session"
pkg install -y php83-session

step "Install package php83-simplexml"
pkg install -y php83-simplexml

step "Install package php83-sodium"
pkg install -y php83-sodium

step "Install package php83-sysvsem"
pkg install -y php83-sysvsem

step "Install package php83-xml"
pkg install -y php83-xml

step "Install package php83-xmlreader"
pkg install -y php83-xmlreader

step "Install package php83-xmlwriter"
pkg install -y php83-xmlwriter

step "Install package php83-xsl"
pkg install -y php83-xsl

step "Install package php83-zip"
pkg install -y php83-zip

step "Install package php83-zlib"
pkg install -y php83-zlib

# php82-pecl-imagick installs ImageMagick7 as dependency.
#step "Install package ImageMagick6-nox11"
#pkg install -y ImageMagick6-nox11

step "Install package ImageMagick7"
pkg install -y ImageMagick7

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


# ---------------- SETUP PORTS -----------------

# leave this enabled
step "Install git-lite"
pkg install -y git-lite

#step "Add openssl to make.conf"
#echo "BATCH=yes" > /etc/make.conf
#echo "DEFAULT_VERSIONS+=ssl=openssl" >> /etc/make.conf
##echo "OPTIONS_SET+= " >> /etc/make.conf

#step "Make directory /usr/ports"
#mkdir -p /usr/ports

#step "Clone ports repo (slow, large)"
#git clone https://git.freebsd.org/ports.git /usr/ports

#step "Checkout the quarterly distribution"
#cd /usr/ports
#git checkout 2024Q3

#step "Build libheif"
#cd /usr/ports/graphics/libheif/
#make install clean BATCH=YES

#step "Build ffmpeg"
#cd /usr/ports/multimedia/ffmpeg/
#make install clean BATCH=YES NO_CHECKSUM=yes

#step "Build ImageMagick7"
#cd /usr/ports/graphics/ImageMagick7/
#make install clean BATCH=YES

#step "Change directory to /root"
#cd /root

#step "Remove /usr/ports"
#rm -rf /usr/ports

# --------------- CLEAN PACKAGES ---------------

step "Package autoremove"
pkg autoremove -y

step "Clean package installation"
pkg clean -ay

step "Create necessary directories if they don't exist"
# Create mountpoints
mkdir /.snapshots

step "Enable nginx"
service nginx enable

# php-fpm is now php_fpm
step "Enable php-fpm"
#service php_fpm enable
if [ -x /usr/local/etc/rc.d/php_fpm ] && [ ! -x /usr/local/etc/rc.d/php-fpm ]; then
    service php_fpm enable || true
else
    service php-fpm enable || true
fi


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
