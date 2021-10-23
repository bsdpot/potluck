#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# if /mnt/prometheus does not exist, create it and set permissions
if [ ! -d /mnt/prometheus ]; then
    mkdir -p /mnt/prometheus
fi
chown -R prometheus:prometheus /mnt/prometheus

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

## start prometheus config
< "$TEMPLATEPATH/prometheus.yml.in" \
  sed "s${sep}%%consulservers%%${sep}$SCRAPECONSUL${sep}g" | \
  sed "s${sep}%%nomadservers%%${sep}$SCRAPENOMAD${sep}g" | \
  sed "s${sep}%%your_vault_server_here%%${sep}$VAULTSERVER${sep}g" | \
  sed "s${sep}%%dbservers%%${sep}$SCRAPEDATABASE${sep}g" \
  > /usr/local/etc/prometheus.yml

# enable prometheus service
service prometheus enable
sysrc prometheus_data_dir="/mnt/prometheus"
sysrc prometheus_syslog_output_enable="YES"

## end prometheus config

## start alertmanager config

< "$TEMPLATEPATH/alertmanager.yml.in" \
  sed "s${sep}%%smtphostport%%${sep}$SMTPHOSTPORT${sep}g" | \
  sed "s${sep}%%smtpfrom%%${sep}$SMTPFROM${sep}g" | \
  sed "s${sep}%%smtpuser%%${sep}$SMTPUSER${sep}g" | \
  sed "s${sep}%%smtppass%%${sep}$SMTPPASS${sep}g" | \
  sed "s${sep}%%alertaddress%%${sep}$ALERTADDRESS${sep}g" \
  > /usr/local/etc/alertmanager/alertmanager.yml

service alertmanager enable
sysrc alertmanager_data_dir="/mnt/alertmanager"
chown -R alertmanager:alertmanager /mnt/alertmanager
## end alertmanager config

# starting services happens in cook script