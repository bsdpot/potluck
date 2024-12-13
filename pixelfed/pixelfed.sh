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
RUNS_IN_NOMAD=false

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
  echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' \
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

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

step "Clean freebsd-update"
rm -rf /var/db/freebsd-update
mkdir -p /var/db/freebsd-update

# we need consul for consul agent
step "Install package consul"
pkg install -y consul

step "Install package openssl"
pkg install -y openssl

step "Install package sudo"
pkg install -y sudo

# necessary if installing curl now
step "Install package ca_root_nss"
pkg install -y ca_root_nss

step "Install package curl"
pkg install -y curl

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package nano"
pkg install -y nano

step "Install package bash"
pkg install -y bash

step "Install package git-lite"
pkg install -y git-lite

step "Install package python311"
pkg install -y python311

step "Install package py311-supervisor"
pkg install -y py311-supervisor

step "Install package postgresql15-client"
pkg install -y postgresql15-client

step "Install package rsync"
pkg install -y rsync

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package blackbox_exporter"
pkg install -y blackbox_exporter

step "Install package nginx"
pkg install -y nginx

step "Install package redis"
pkg install -y redis

step "Install package ffmpeg"
pkg install -y ffmpeg

step "Install package node20"
pkg install -y node20

step "Install package yarn-node20"
pkg install -y yarn-node20

# this automatically installs ImageMagick7-nox11 too
step "Install package vips-nox11"
pkg install -y vips-nox11

step "Install package ImageMagick7-nox11"
pkg install -y ImageMagick7-nox11

step "Install package php83"
pkg install -y php83

step "Install package php83-mbstring"
pkg install -y php83-mbstring

step "Install package php83-zlib"
pkg install -y php83-zlib

step "Install package php83-curl"
pkg install -y php83-curl

step "Install package php83-gd"
pkg install -y php83-gd

step "Install package php83-bcmath"
pkg install -y php83-bcmath

step "Install package php83-ctype"
pkg install -y php83-ctype

step "Install package php83-exif"
pkg install -y php83-exif

step "Install package php83-iconv"
pkg install -y php83-iconv

step "Install package php83-intl"
pkg install -y php83-intl

step "Install package php83-pecl-redis"
pkg install -y php83-pecl-redis

step "Install package php83-tokenizer"
pkg install -y php83-tokenizer

step "Install package php83-simplexml"
pkg install -y php83-simplexml

step "Install package php83-xml"
pkg install -y php83-xml

step "Install package php83-xmlreader"
pkg install -y php83-xmlreader

step "Install package php83-xmlwriter"
pkg install -y php83-xmlwriter

step "Install package php83-fileinfo"
pkg install -y php83-fileinfo

step "Install package php83-pcntl"
pkg install -y php83-pcntl

step "Install package php83-sodium"
pkg install -y php83-sodium

step "Install package php83-posix"
pkg install -y php83-posix

step "Install package php83-zip"
pkg install -y php83-zip

step "Install package php83-pgsql"
pkg install -y php83-pgsql

step "Install package php83-pdo_pgsql"
pkg install -y php83-pdo_pgsql

step "Install package php83-mysqli"
pkg install -y php83-mysqli

step "Install package php83-pdo_mysql"
pkg install -y php83-pdo_mysql

step "Install package php83-composer"
pkg install -y php83-composer

step "Install package php83-pecl-imagick"
pkg install -y php83-pecl-imagick

step "Install package syslog-ng"
pkg install -y syslog-ng

# ---------------- SETUP PORTS -----------------

#step "Add openssl settings to make.conf"
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

# -------------- END PACKAGE SETUP -------------

# make directory for pixelfed
step "Make directory for pixelfed"
mkdir -p /usr/local/www/pixelfed

step "Setting www:www owner of /usr/local/www/pixelfed"
chown -R www:www /usr/local/www/pixelfed

step "Initiating git repo in /usr/local/www/pixelfed"
su -m www -c "cd /usr/local/www/pixelfed; git init -b dev"

step "Adding remote origin https://github.com/pixelfed/pixelfed.git"
su -m www -c "cd /usr/local/www/pixelfed; git remote add origin https://github.com/pixelfed/pixelfed.git"

step "Running git fetch"
su -m www -c "cd /usr/local/www/pixelfed; git fetch"

step "Checking out the latest commit"
#su -m www -c "cd /usr/local/www/pixelfed; git checkout e9bcc52944ffab87d9971f21832046942058570d"
# https://github.com/pixelfed/pixelfed/commit/ceb375d91d736e72f31931e19701b6cff191d0db
# lock to release v0.12.4 on 2024-11-09
su -m www -c "cd /usr/local/www/pixelfed; git checkout 65dd601a02f5840c9d3e25bb30cfbbd8d033d8ae"

# include --no-cache because user www can't create cache dir in /root
step "Run composer install"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/composer install --no-ansi --no-interaction --optimize-autoloader --no-cache"

# include --no-cache because user www can't create cache dir in /root
step "Run composer update"
su -m www -c "cd /usr/local/www/pixelfed; /usr/local/bin/composer update --no-cache"

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
