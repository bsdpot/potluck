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

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

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

step "Install package rsync"
pkg install -y rsync

step "Install package node_exporter"
pkg install -y node_exporter

# nginx-full has conflicts and will remove any nginx
step "Install package nginx"
pkg install -y nginx

step "Install package syslog-ng"
pkg install -y syslog-ng

step "Install package acme.sh"
pkg install -y acme.sh

step "Install package gnupg"
pkg install -y gnupg

step "Install package wget"
pkg install -y wget

step "Install package postgresql13-client"
pkg install -y postgresql13-client

step "Install package postgresql13-server"
pkg install -y postgresql13-server

step "Install package redis"
pkg install -y redis

step "Install package yarn"
pkg install -y yarn

step "Install package npm"
pkg install -y npm

step "Install package git"
pkg install -y git

step "Install package go"
pkg install -y go

step "Install package gmake"
pkg install -y gmake

step "Install package autoconf"
pkg install -y autoconf

step "Install package ffmpeg"
pkg install -y ffmpeg

step "Install package rubygem-bundler"
pkg install -y rubygem-bundler

step "Install package ImageMagick7-nox11"
pkg install -y ImageMagick7-nox11

step "Install package libidn"
pkg install -y libidn

step "Install package icu"
pkg install -y icu

step "Install package bison"
pkg install -y bison

step "Install package libyaml"
pkg install -y libyaml

step "Install package libffi"
pkg install -y libffi

step "Install package libxml2"
pkg install -y libxml2

step "Install package libxslt"
pkg install -y libxslt

step "Install package libyaml"
pkg install -y libyaml

step "Install package readline"
pkg install -y readline

step "Install package mastodon"
pkg install -y mastodon

step "Clean package installation"
pkg clean -y

# -------------- END PACKAGE SETUP -------------

# ----------- BEGIN POSTGRES EXPORTER-----------
#
# duplicated from postgresql-patroni, updated to latest version

cd /tmp

step "Download postgres_exporter from github"

/usr/local/bin/git clone --depth 1 -b v0.13.2 \
  https://github.com/prometheus-community/postgres_exporter.git

# make sure we're at the correct commit
cd /tmp/postgres_exporter
/usr/local/bin/git checkout 8c3604b85e38ae7141e84ecdc318b6015a196c97

# build
/usr/local/bin/gmake build

cd /tmp

step "Install postgres_exporter"
sed -i '' 's|-web.listen-address|--web.listen-address|g' \
  /tmp/postgres_exporter/postgres_exporter.rc
# shellcheck disable=SC2016
sed -i '' 's|-p ${pidfile}|-f -p ${pidfile} -T ${name}|g' \
  /tmp/postgres_exporter/postgres_exporter.rc
cp -f /tmp/postgres_exporter/postgres_exporter.rc \
  /usr/local/etc/rc.d/postgres_exporter
chmod +x /usr/local/etc/rc.d/postgres_exporter
cp -f /tmp/postgres_exporter/postgres_exporter \
  /usr/local/bin/postgres_exporter
chmod +x /usr/local/bin/postgres_exporter

step "Clean postgres_exporter build"
rm -rf /tmp/postgres_exporter

# ------------ BEGIN MASTODON CUSTOM -----------

# The FreeBSD wiki has a set of instructions
# https://wiki.freebsd.org/Ports/net-im/mastodon
# however it is missing a step to 'yarn add node-gyp'
# as covered in the Bastillefile at
# https://codeberg.org/ddowse/mastodon/src/branch/main/Bastillefile

# We setup the bundle and yarn steps here in order to make them happen
# during image build, to avoid delaying the pot image boot process

step "enable corepack"
/usr/local/bin/corepack enable

step "Add node-gyp to yarn"
/usr/local/bin/yarn add node-gyp

step "user mastodon - set yarn classic"
su - mastodon -c "/usr/local/bin/yarn set version classic"

step "user mastodon - enable deployment"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle config deployment 'true'"

step "user mastodon - remove development and test environments"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle config without 'development test'"

step "user mastodon - bundle install"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle install -j1"

step "user mastodon - yarn install process"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/yarn install --pure-lockfile"

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
