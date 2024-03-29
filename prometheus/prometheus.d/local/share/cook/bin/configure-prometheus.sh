#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# Create prometheus dirs and set permissions
# Note: Alerts can be preloaded before image starts
mkdir -p /mnt/prometheus/alerts
cp -a "$TEMPLATEPATH"/prometheusalerts/*.yml /mnt/prometheus/alerts/.
chown -R prometheus:prometheus /mnt/prometheus

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

CONSUL_METRICS_TOKEN=$(cat /mnt/consulcerts/consul_metrics.token)

## start prometheus config
< "$TEMPLATEPATH/prometheus.yml.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%consulservers%%${sep}$SCRAPECONSUL${sep}g" | \
  sed "s${sep}%%consul_metrics_token%%${sep}$CONSUL_METRICS_TOKEN${sep}g" | \
  sed "s${sep}%%nomadservers%%${sep}$SCRAPENOMAD${sep}g" \
  > /usr/local/etc/prometheus.yml

# enable prometheus service
service prometheus enable
sysrc prometheus_data_dir="/mnt/prometheus"
sysrc prometheus_syslog_output_enable="YES"
sysrc prometheus_args="--web.listen-address=127.0.0.1:9090 \
--storage.tsdb.retention=2y"

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

service alertmanager enable
sysrc alertmanager_data_dir="/mnt/alertmanager"
sysrc alertmanager_args="--web.listen-address=127.0.0.1:9093\
 --cluster.listen-address=''"

# if /mnt/altermanager does not exist, create it and set permissions
if [ ! -d /mnt/alertmanager ]; then
    mkdir -p /mnt/alertmanager
fi

# make alertmanager templates directory copy over notification templates
mkdir -p /mnt/alertmanager/templates
cp -a "$TEMPLATEPATH"/alertmanagertemplates/*.tmpl \
  /mnt/alertmanager/templates/.

# set permissions on /mnt/alertmanager
chown -R alertmanager:alertmanager /mnt/alertmanager

## end alertmanager config

# starting services happens in cook script
