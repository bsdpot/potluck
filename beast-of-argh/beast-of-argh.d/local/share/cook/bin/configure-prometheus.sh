#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# Create prometheus dirs and set permissions
# Note: Alerts can be preloaded before image starts
mkdir -p /mnt/prometheus/alerts
cp -a "$TEMPLATEPATH"/prometheusalerts/*.yml /mnt/prometheus/alerts/.
chown -R prometheus:prometheus /mnt/prometheus

# create file-based-targets dir, copy in sample files if don't exist,
# and set uid/gid recursively on the directory
mkdir -p /mnt/prometheus/targets.d
if [ ! -f /mnt/prometheus/targets.d/mytargets.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/mytargets.yml /mnt/prometheus/targets.d/mytargets.yml
fi
if [ ! -f /mnt/prometheus/targets.d/postgres.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/postgres.yml /mnt/prometheus/targets.d/postgres.yml
fi
if [ ! -f /mnt/prometheus/targets.d/minio.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/minio.yml /mnt/prometheus/targets.d/minio.yml
fi
if [ ! -f /mnt/prometheus/targets.d/mysql.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/mysql.yml /mnt/prometheus/targets.d/mysql.yml
fi
if [ ! -f /mnt/prometheus/targets.d/redis.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/redis.yml /mnt/prometheus/targets.d/redis.yml
fi
if [ ! -f /mnt/prometheus/targets.d/blackboxicmp.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/blackboxicmp.yml /mnt/prometheus/targets.d/blackboxicmp.yml
fi
if [ ! -f /mnt/prometheus/targets.d/blackboxhttpget.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/blackboxhttpget.yml /mnt/prometheus/targets.d/blackboxhttpget.yml
fi
if [ ! -f /mnt/prometheus/targets.d/blackboxtcpconnect.yml ]; then
    cp -a "$TEMPLATEPATH"/sampletargets/blackboxtcpconnect.yml /mnt/prometheus/targets.d/blackboxtcpconnect.yml
fi
chown -R prometheus:prometheus /mnt/prometheus/targets.d

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

## start prometheus config
< "$TEMPLATEPATH/prometheus.yml.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%consulservers%%${sep}$FIXSCRAPECONSUL${sep}g" | \
  sed "s${sep}%%nomadservers%%${sep}$FIXSCRAPENOMAD${sep}g" | \
  sed "s${sep}%%traefikserver%%${sep}$FIXTRAEFIKSERVER${sep}g" \
  > /usr/local/etc/prometheus.yml

# enable prometheus service
service prometheus enable || true
sysrc prometheus_data_dir="/mnt/prometheus" || true
sysrc prometheus_syslog_output_enable="YES" || true
echo "prometheus_args=\"--web.listen-address=$IP:9090\"" >> /etc/rc.conf

## end prometheus config

## start alertmanager config

< "$TEMPLATEPATH/alertmanager.yml.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%smtphostport%%${sep}$SMTPHOSTPORT${sep}g" | \
  sed "s${sep}%%smtpfrom%%${sep}$SMTPFROM${sep}g" | \
  sed "s${sep}%%smtpuser%%${sep}$SMTPUSER${sep}g" | \
  sed "s${sep}%%smtppass%%${sep}$SMTPPASS${sep}g" | \
  sed "s${sep}%%alertaddress%%${sep}$ALERTADDRESS${sep}g" \
  > /usr/local/etc/alertmanager/alertmanager.yml

service alertmanager enable || true
sysrc alertmanager_data_dir="/mnt/alertmanager" || true
echo "alertmanager_args=\"--web.listen-address=$IP:9093 --cluster.listen-address=''\"" >> /etc/rc.conf

# if /mnt/altermanager does not exist, create it and set permissions
if [ ! -d /mnt/alertmanager ]; then
    mkdir -p /mnt/alertmanager
fi

# make alertmanager templates directory copy over notification templates
mkdir -p /mnt/alertmanager/templates
cp -a "$TEMPLATEPATH"/alertmanagertemplates/*.tmpl /mnt/alertmanager/templates/.

# set permissions on /mnt/alertmanager
chown -R alertmanager:alertmanager /mnt/alertmanager

## end alertmanager config

# starting services happens in cook script
