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

step "Update package repository"
pkg update -f

step "Install package sudo"
pkg install -y sudo

step "Install package openssl"
pkg install -y openssl

step "Install package nginx"
pkg install -y nginx

step "Install package vault"
pkg install -y vault

step "Install package consul"
pkg install -y consul

step "Install package consul-template"
pkg install -y consul-template

step "Patching consul-template rc scripts"
sed -i '' 's/^\(start_precmd=consul_template_startprecmd\)$/\1;'\
'extra_commands=reload/'  /usr/local/etc/rc.d/consul-template || true

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package syslog-ng"
pkg install -y syslog-ng

step "Install package postgresql-server"
pkg install -y postgresql13-server

step "Install package postgresql-client"
pkg install -y postgresql13-client

step "Install package postgresql-contrib"
pkg install -y postgresql13-contrib

step "Install package python39"
pkg install -y python39

step "Install package python3-pip"
pkg install -y py39-pip

step "Install package python-consul2"
# this version gives error
pkg install -y py39-python-consul2

# using pip to install this package, as pkg removes postgres13 now,
# and installs postgres12 client as dependency
#step "Install package psycopg2"
#pkg install -y py39-psycopg2

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package curl"
pkg install -y curl

#
# pip MUST ONLY be used:
# * With the --user flag, OR
# * To install or manage Python packages in virtual environments
# using -prefix here to force install in /usr/local/bin

step "Install pip package psycopg2-binary"
pip install psycopg2-binary --prefix="/usr/local/"

step "Install pip package patroni"
pip install patroni --prefix="/usr/local"
#
## WARNING: The scripts patroni, patroni_aws, patroni_raft_controller,
## patroni_wale_restore and patronictl are installed in
## '--prefix=/usr/local/bin' which is not in PATH.
## Consider adding this directory to PATH or, if you prefer to suppress
## this warning, use --no-warn-script-location.

#### Build postgres_exporter - BEGIN
# change to a temporary directory and clone the github repo for
# postgres_exporter
step "Install package git-lite"
pkg install -y git-lite

step "Install package go"
pkg install -y go

step "Install package gmake"
pkg install -y gmake

cd /tmp

step "Fetch postgres_exporter sources"
/usr/local/bin/git clone --depth 1 -b v0.10.1 \
  https://github.com/prometheus-community/postgres_exporter.git
# make sure we're at the correct commit

step "Build postgres_exporter"
cd /tmp/postgres_exporter
# make sure we're at the expected commit
/usr/local/bin/git checkout 6cff384d7433bcb1104efe3b496cd27c0658eb09
/usr/local/bin/gmake build

step "Install postgres_exporter"
sed -i '' 's|-web.listen-address|--web.listen-address|g' \
  /tmp/postgres_exporter/postgres_exporter.rc
sed -i '' 's|sslmode=disable|sslmode=verify-ca|g' \
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
pkg delete -y git-lite gmake go

#### Build postgres_exporter - END

step "Clean package installation"
pkg clean -y

# -------------- END PACKAGE SETUP -------------
#
# Create configurations
#

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
