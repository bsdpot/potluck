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

step "Disable sshd"
service sshd onedisable || true

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

step "Clean freebsd-update"
rm -rf /var/db/freebsd-update
mkdir -p /var/db/freebsd-update

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

step "Install package syslog-ng"
pkg install -y syslog-ng

# ------------- MAILHUB PACKAGES ---------------

step "Install package perl5"
pkg install -y perl5

step "Install package p5-Encode-Detect"
pkg install -y p5-Encode-Detect

step "Install package p5-HTML-Parser"
pkg install -y p5-HTML-Parser

step "Install package p5-HTTP-Date"
pkg install -y p5-HTTP-Date

step "Install package p5-Net-DNS"
pkg install -y p5-Net-DNS

step "Install package p5-NetAddr-IP"
pkg install -y p5-NetAddr-IP

step "Install package p5-Net-CIDR-Lite"
pkg install -y p5-Net-CIDR-Lite

step "Install package p5-Net-IDN-Encode"
pkg install -y p5-Net-IDN-Encode

step "Install package p5-Net-LibIDN"
pkg install -y p5-Net-LibIDN

step "Install package p5-URI"
pkg install -y p5-URI

step "Install package p5-IO-Socket-SSL"
pkg install -y p5-IO-Socket-SSL

step "Install package p5-Mail-DKIM"
pkg install -y p5-Mail-DKIM

step "Install package p5-Crypt-OpenSSL-RSA"
pkg install -y p5-Crypt-OpenSSL-RSA

step "Install package p5-Mail-SPF"
pkg install -y p5-Mail-SPF

step "Install package p5-IO-Socket-SSL"
pkg install -y p5-IO-Socket-SSL

step "Install package p5-Class-XSAccessor"
pkg install -y p5-Class-XSAccessor

step "Install package p5-XString"
pkg install -y p5-XString

step "Install package re2c"
pkg install -y re2c

step "Install package gnupg1"
pkg install -y gnupg1

step "Install package postfix-ldap"
pkg install -y postfix-ldap

step "Install package pkgconf"
pkg install -y pkgconf

step "Install package zstd"
pkg install -y zstd

step "Install package python39"
pkg install -y python39

step "Install package acme.sh"
pkg install -y acme.sh

step "Install package clamav"
pkg install -y clamav

step "Install package opendkim"
pkg install -y opendkim

step "Install package opendmarc"
pkg install -y opendmarc

step "Install package mail/py-spf-engine"
pkg install -y mail/py-spf-engine

step "Install package openldap26-client"
pkg install -y openldap26-client

step "Install package consul"
pkg install -y consul

step "Install package node_exporter"
pkg install -y node_exporter

# ---------------- SETUP PORTS -----------------

step "Install package git-lite"
pkg install -y git-lite

step "Install package go"
pkg install -y go

step "Add openssl and ldap settings to make.conf"
echo "BATCH=yes" > /etc/make.conf
echo "DEFAULT_VERSIONS+=ssl=openssl" >> /etc/make.conf
echo "OPTIONS_SET+= GSSAPI_NONE LDAP MYSQL RAZOR" >> /etc/make.conf

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
  archivers/zstd \
  mail/dovecot/ \
  mail/dovecot-pigeonhole/ \
  mail/spamassassin/ \
  lang/python39/ \
  ports-mgmt/pkg/ \
  converters/p5-Encode-Detect/ \
  converters/libiconv/ \
  www/p5-HTML-Parser/ \
  www/p5-HTTP-Date/ \
  dns/p5-Net-DNS/ \
  net-mgmt/p5-NetAddr-IP/ \
  net/p5-Net-CIDR-Lite/ \
  textproc/p5-Net-IDN-Encode/ \
  dns/p5-Net-LibIDN/ \
  net/p5-URI/ \
  devel/re2c/ \
  devel/pkgconf \
  security/p5-IO-Socket-SSL/ \
  mail/p5-Mail-DKIM/ \
  security/p5-Crypt-OpenSSL-RSA/ \
  security/gnupg1/ \
  mail/p5-Mail-SPF/ \
  mail/dcc-dccd/ \
  databases/p5-DBD-mysql/ \
  databases/p5-DBD-Pg/ \
  databases/mysql80-client \
  databases/mysql80-server \
  mail/pyzor/ \
  mail/razor-agents/ \
  security/p5-Digest-SHA1/ \
  net/p5-GeoIP2/ \
  net/p5-IP-Country/ \
  net/p5-IO-Socket-INET6 \
  net/p5-Socket6 \
  net/openldap26-client \
  net/openldap26-server \
  devel/p5-BSD-Resource/

# checkout quarterly branch instead
# https://wiki.freebsd.org/Ports/QuarterlyBranch
#  "Branches are named according to the year (YYYY)
#   and quarter (Q1-4) they are created in.
#   For example, the quarterly branch created in
#   January 2016, is named 2016Q1."
# Quarterly in Feb 2023 is 2023Q1
step "Pull files"
#git pull --depth=1 origin main
#git pull --depth=1 origin 2022Q3
#git pull --depth=1 origin 2022Q4
#git pull --depth=1 origin 2023Q1
#git pull --depth=1 origin 2023Q2
#git pull --depth=1 origin 2023Q3
#git pull --depth=1 origin 2024Q1
#git pull --depth=1 origin 2024Q2
#git pull --depth=1 origin 2024Q3
git pull --depth=1 origin 2024Q4

#step "Port build openssl, remove existing, replace with this port"
##required for latest / main branch
#cd /usr/ports/security/openssl/
#make clean BATCH=1
#make deinstall BATCH=1
#make reinstall BATCH=1

# If openssl port installed, then can build dovecot without giving the error:
#   make: /usr/ports/Mk/Uses/ssl.mk line 95: You are using an unsupported SSL provider openssl
step "Port build dovecot"
cd /usr/ports/mail/dovecot/
make install clean LDAP=ON BATCH=YES
cp -R /usr/local/etc/dovecot/example-config/* /usr/local/etc/dovecot

step "Port build dovecot-pigeonhole"
cd /usr/ports/mail/dovecot-pigeonhole/
make install clean LDAP=ON BATCH=YES

step "Port build spamassassin"
cd /usr/ports/mail/spamassassin/
make reinstall MYSQL=ON RAZOR=ON BATCH=YES

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


# ------------- DIRECTORY CREATION -------------

# make necessary directories
mkdir -p /mnt/postfix
mkdir -p /mnt/acme
mkdir -p /mnt/spamassassin
mkdir -p /mnt/dovecot
mkdir -p /mnt/opendkim
mkdir -p /mnt/opendmarc
mkdir -p /root/bin

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
