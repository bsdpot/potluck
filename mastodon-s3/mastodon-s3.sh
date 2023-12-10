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
# this is a non-layered image now, with latest package sources
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

# dependency is postgres15-client not postgres13-client
step "Install package postgresql15-client"
pkg install -y postgresql15-client

# we still need to install redis for redis-cli, but
# we don't configure or start it
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

# Mastodon will install ImageMagick7 regardless of this
#step "Install package ImageMagick7-nox11"
#pkg install -y ImageMagick7-nox11

# this install wayland and lots of bloated packages
step "Install package ImageMagick7"
pkg install -y ImageMagick7

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

step "Clean package installation"
pkg clean -y

# -------------- END PACKAGE SETUP -------------

# ------------ BEGIN MASTODON BUILD ------------
# create mastodon user without -m, --create-home
if ! id -u "mastodon" >/dev/null 2>&1; then
  /usr/sbin/pw useradd -n mastodon -c 'Mastodon User' -d /usr/local/www/mastodon -s /bin/sh -h -
fi

# make sure we have /usr/local/www/mastodon
mkdir -p /usr/local/www/mastodon

# set perms on /usr/local/www/mastodon to mastodon:mastodon
chown -R mastodon:mastodon /usr/local/www/mastodon

# if we do not have /usr/local/www/mastodon/.git then
# configure /usr/local/www/mastodon as git repo and pull files
if [ ! -d /usr/local/www/mastodon/.git ]; then
    echo "Initiating git repo in /usr/local/www/mastodon"
    su - mastodon -c "cd /usr/local/www/mastodon; git init"
    # add custom fork with 5k limit and 4.2.3 patches
    echo "Adding remote origin https://github.com/hny-gd/mastodon.git"
    su - mastodon -c "cd /usr/local/www/mastodon; git remote add origin https://github.com/hny-gd/mastodon.git"
    echo "Running git fetch"
    su - mastodon -c "cd /usr/local/www/mastodon; git fetch"
    echo "Checking out the mastodon release we want"
    su - mastodon -c "cd /usr/local/www/mastodon; git checkout stable-4.2"
else
    echo ".git directory exists, not cloning repo"
fi

# moved from base file mastodon-s3.sh in anticipation switch to install from github
#
# The FreeBSD wiki has a set of instructions
# https://wiki.freebsd.org/Ports/net-im/mastodon
# however it is missing a step to 'yarn add node-gyp'
# as covered in the Bastillefile at
# https://codeberg.org/ddowse/mastodon/src/branch/main/Bastillefile

# not needed any more
# Update Gemfile for older version json-canonicalization
# Remove this when fixed in source for workaround for json-canonicalization (1.0.0)
#cp -f "$TEMPLATEPATH/Gemfile.lock.in" /usr/local/www/mastodon/Gemfile.lock
#chown  mastodon:mastodon /usr/local/www/mastodon/Gemfile.lock

# enable corepack
echo "Enabling corepack"
/usr/local/bin/corepack enable

# Add node-gyp to yarn
echo "Adding node-gyp to yarn"
/usr/local/bin/yarn add node-gyp

# as user mastodon - set yarn classic
# enable this for wogan fork
echo "Setting yarn to classic version"
su - mastodon -c "/usr/local/bin/yarn set version classic"
# undo this for wogan fork
#echo "Setting yarn to stable version"
#su - mastodon -c "/usr/local/bin/yarn set version stable"

# as user mastodon - enable deployment
echo "Setting mastodon deployment to true"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle config deployment 'true'"

# as user mastodon - remove development and test environments
echo "Removing development and test environments"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle config without 'development test'"

# Left out as not working, may be relevant for FBSD 14
# might require cbor and posix-spawn gems installed first
#########
# as user mastodon add extra adjustments to bundle as per https://wiki.freebsd.org/Ports/net-im/mastodon
# (Needed for 13.2-STABLE and 14.0-RELEASE and later)
#echo "Setting Wno-incompatible-function-pointer-types flag for build.cbor"
## not working: Could not find command "build.cbor".
#su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle build.cbor --with-cflags='-Wno-incompatible-function-pointer-types'"
#echo "Setting Wno-incompatible-function-pointer-types flag for build.posix-spawn"
## not working: Could not find command "build.posix-spawn"
#su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle build.posix-spawn --with-cflags='-Wno-incompatible-function-pointer-types'"
#########

# not needed any more
# unfreeze the gem because we're using newer json-canonicalization (1.0.0)
# remove this when fixed in source, keep as record
#su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle config set frozen false"

# as user mastodon - bundle install
echo "Installing the required files with bundle"
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/bundle install -j1"

# add babel-plugin-lodash@3.3.4 compression-webpack-plugin@6.1.1
# this is a temp fix for the error about missing versions
# "Using --ignore-workspace-root-check or -W allows a package to be installed at the workspaces root.
# This tends not to be desired behaviour, as dependencies are generally expected to be part of a workspace."
# disable for wogan fork, testing
#echo "Adding yarn package dependancies - temp fix"
## no -W with yarn stable aka version 4+
##su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/yarn add babel-plugin-lodash@3.3.4 compression-webpack-plugin@10.0.0 -W"

# as user mastodon - yarn install process
echo "Installing the required files with yarn"
# enable for wogan fork
su - mastodon -c "cd /usr/local/www/mastodon && /usr/local/bin/yarn install --pure-lockfile"

# ----------- END CUSTOM MASTODON ---------------

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
