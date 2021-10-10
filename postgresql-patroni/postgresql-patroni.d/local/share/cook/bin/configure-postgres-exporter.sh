#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# change to a temporary directory and clone the github repo for postgres_exporter
cd /tmp

# glone the github repo
/usr/local/bin/git clone https://github.com/prometheus-community/postgres_exporter.git

# change to the directory with the local repo
cd /tmp/postgres_exporter

# build the application using gmake, no configuration required beforehand
/usr/local/bin/gmake build

# add startup file to system, but fix bug in file before copy
sed -i .orig 's|-web.listen-address|--web.listen-address|g' /tmp/postgres_exporter/postgres_exporter.rc

# you can enable sslmode too
#sed -i .orig 's|sslmode=disable|sslmode=require|g' /tmp/postgres_exporter/postgres_exporter.rc

# force copy over postgres_exporter rc file to /usr/local/etc/rc.d
cp -f /tmp/postgres_exporter/postgres_exporter.rc /usr/local/etc/rc.d/postgres_exporter

# make postgres_exporter startup script executable
chmod +x /usr/local/etc/rc.d/postgres_exporter

# force copy over postgres_exporter binary to /usr/local/bin
cp -f /tmp/postgres_exporter/postgres_exporter /usr/local/bin/postgres_exporter

# make postgres_exporter binary executable
chmod +x /usr/local/bin/postgres_exporter

# set startup options for postgres_export, one of them a manual way to get the IP address in
sysrc postgres_exporter_enable="YES"
sysrc postgres_exporter_pg_host="$IP"
sysrc postgres_exporter_pg_user="postgres"

# this probably shouldn't be in /etc/rc.conf file but only way atm
sysrc postgres_exporter_pg_pass="$KEKPASS"

# return to base directory as done with postgres_exporter setup
cd /root
