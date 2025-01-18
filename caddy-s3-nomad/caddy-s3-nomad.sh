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
# added for images with switch to latest
ASSUME_ALWAYS_YES=yes pkg update

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

step "Install package jq"
pkg install -y jq

step "Install package nano"
pkg install -y nano

step "Install package sudo"
pkg install -y sudo

step "Install package unzip"
pkg install -y unzip

step "Install package acme.sh"
pkg install -y acme.sh

step "Install package git-lite"
pkg install -y git-lite

step "Install package lang/go"
pkg install -y lang/go



# -------------- END PACKAGE SETUP -------------

# -------------- START PORTS SETUP--------------

echo "BATCH=yes" > /etc/make.conf
echo "DEFAULT_VERSIONS+=ssl=openssl" >> /etc/make.conf
# removing, not working as expected
#echo "CADDY_CUSTOM_PLUGINS=github.com/ss098/certmagic-s3" >> /etc/make.conf
# new, trying this one
echo "CADDY_CUSTOM_PLUGINS=github.com/lindenlab/caddy-s3-proxy" >> /etc/make.conf

step "Make directory /usr/ports"
mkdir -p /usr/ports

step "Init packages git branch main"
cd /usr/ports
git init -b main

step "Add packages remote origin"
git remote add origin https://git.freebsd.org/ports.git

step "Git sparse checkout init"
git sparse-checkout init

step "Checkout ports and supporting files"
git sparse-checkout set GIDs UIDs \
  Mk/ \
  Templates/ \
  Keywords/ \
  lang/perl5.36/ \
  security/openssl/ \
  ports-mgmt/pkg/ \
  lang/go121/ \
  lang/go-devel/ \
  lang/go/ \
  www/caddy/ \
  www/xcaddy/ \
  www/caddy-custom/

# checkout quarterly branch instead
# https://wiki.freebsd.org/Ports/QuarterlyBranch
#  "Branches are named according to the year (YYYY)
#   and quarter (Q1-4) they are created in.
#   For example, the quarterly branch created in
#   January 2016, is named 2016Q1."
# Quarterly in Aug 2023 is 2023Q3
step "Pull files"
#git pull --depth=1 origin 2023Q3
#git pull --depth=1 origin 2024Q2
#git pull --depth=1 origin 2024Q4
git pull --depth=1 origin 2025Q1

# go straight to building caddy-custom
#step "Build caddy"
#cd /usr/ports/www/caddy/
#make install clean BATCH=YES

# go straight to building caddy-custom
#step "Build xcaddy"
#cd /usr/ports/www/xcaddy/
#make install clean BATCH=YES

step "Build caddy-custom"
cd /usr/ports/www/caddy-custom/
make install clean BATCH=YES

step "Change directory to /root"
cd /root

step "Remove /usr/ports"
rm -rf /usr/ports

# --------------- CLEAN PACKAGES ---------------

step "Package autoremove"
pkg autoremove -y

step "Clean package installation"
pkg clean -ay

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
