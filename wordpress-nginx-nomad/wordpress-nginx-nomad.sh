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

step "Install package sudo"
pkg install -y sudo

step "Install package nginx"
pkg install -y nginx

step "Install package mariadb106-client"
pkg install -y mariadb106-client

step "Install package postgresql15-client"
pkg install -y postgresql15-client

step "Install package php82"
pkg install -y php82

step "Install package php82-extensions"
pkg install -y php82-extensions

step "Install package ImageMagick7-nox11"
pkg install -y ImageMagick7-nox11

step "Install package avahi-app"
pkg install -y avahi-app

step "Install package bash-completion"
pkg install -y bash-completion

step "Install package cups"
pkg install -y cups

step "Install package dbus"
pkg install -y dbus

step "Install package dbus-glib"
pkg install -y dbus-glib

step "Install package expat"
pkg install -y expat

step "Install package fftw3"
pkg install -y fftw3

step "Install package fontconfig"
pkg install -y fontconfig

step "Install package freetype2"
pkg install -y freetype2

step "Install package fribidi"
pkg install -y fribidi

step "Install package gdbm"
pkg install -y gdbm

#This port expired on: 2023-12-31
#step "Install package ghostscript9-agpl-base"
#pkg install -y ghostscript9-agpl-base

step "Install package ghostscript10"
pkg install -y ghostscript10

step "Install package giflib"
pkg install -y giflib

step "Install package glib"
pkg install -y glib

step "Install package gmp"
pkg install -y gmp

step "Install package gnome_subr"
pkg install -y gnome_subr

step "Install package gnutls"
pkg install -y gnutls

step "Install package graphite2"
pkg install -y graphite2

step "Install package gsfonts"
pkg install -y gsfonts

step "Install package harfbuzz"
pkg install -y harfbuzz

step "Install package jbig2dec"
pkg install -y jbig2dec

step "Install package jbigkit"
pkg install -y jbigkit

step "Install package jpeg-turbo"
pkg install -y jpeg-turbo

step "Install package lcms2"
pkg install -y lcms2

step "Install package libICE"
pkg install -y libICE

step "Install package libSM"
pkg install -y libSM

step "Install package libX11"
pkg install -y libX11

step "Install package libXau"
pkg install -y libXau

step "Install package libXdmcp"
pkg install -y libXdmcp

step "Install package libdaemon"
pkg install -y libdaemon

step "Install package libevent"
pkg install -y libevent

step "Install package libffi"
pkg install -y libffi

step "Install package libgd"
pkg install -y libgd

step "Install package libidn"
pkg install -y libidn

step "Install package libidn2"
pkg install -y libidn2

step "Install package liblqr-1"
pkg install -y liblqr-1

step "Install package libltdl"
pkg install -y libltdl

step "Install package libpaper"
pkg install -y libpaper

# removed
#step "Install package libpthread-stubs"
#pkg install -y libpthread-stubs

step "Install package libraqm"
pkg install -y libraqm

step "Install package libraw"
pkg install -y libraw

step "Install package libtasn1"
pkg install -y libtasn1

step "Install package libunistring"
pkg install -y libunistring

step "Install package libwmf-nox11"
pkg install -y libwmf-nox11

step "Install package libxcb"
pkg install -y libxcb

step "Install package libzip"
pkg install -y libzip

step "Install package nettle"
pkg install -y nettle

step "Install package openjpeg"
pkg install -y openjpeg

step "Install package p11-kit"
pkg install -y p11-kit

step "Install package perl5"
pkg install -y perl5

step "Install package php82-curl"
pkg install -y php82-curl

step "Install package php82-exif"
pkg install -y php82-exif

step "Install package php82-fileinfo"
pkg install -y php82-fileinfo

step "Install package php82-ftp"
pkg install -y php82-ftp

step "Install package php82-gd"
pkg install -y php82-gd

step "Install package php82-mysqli"
pkg install -y php82-mysqli

step "Install package php82-pecl-imagick"
pkg install -y php82-pecl-imagick

step "Install package php82-zip"
pkg install -y php82-zip

step "Install package php82-zlib"
pkg install -y php82-zlib

step "Install package php82-pear"
pkg install -y php82-pear

step "Install package pkgconf"
pkg install -y pkgconf

step "Install package png"
pkg install -y png

step "Install package poppler-data"
pkg install -y poppler-data

step "Install package python311"
pkg install -y python311

step "Install package tiff"
pkg install -y tiff

step "Install package tpm-emulator"
pkg install -y tpm-emulator

step "Install package trousers"
pkg install -y trousers

step "Install package webp"
pkg install -y webp

step "Install package xorgproto"
pkg install -y xorgproto

step "Clean package installation"
pkg clean -y

step "Enable nginx"
service nginx enable

step "Enable php-fpm"
service php-fpm enable

# -------------- Custom directories ------------

# Create .snapshots
step "Create snapshots directory"
mkdir /.snapshots

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
