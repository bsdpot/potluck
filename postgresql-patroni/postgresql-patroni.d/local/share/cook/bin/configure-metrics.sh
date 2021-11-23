#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

echo "Cloning consul-template rc scripts"
cp -a /usr/local/etc/rc.d/consul-template \
  /usr/local/etc/rc.d/consul-template-metrics
sed -i '' 's/consul_template/consul_template_metrics/g' \
  /usr/local/etc/rc.d/consul-template-metrics
sed -i '' 's/consul-template/consul-template-metrics/g' \
  /usr/local/etc/rc.d/consul-template-metrics
ln -s /usr/local/bin/consul-template \
  /usr/local/bin/consul-template-metrics

echo "Writing consul-template-metrics config"
mkdir -p /usr/local/etc/consul-template-metrics.d

TOKEN=$(/bin/cat /mnt/metricscerts/unwrapped.token)

cp "$TEMPLATEPATH/consul-template-metrics.hcl.in" \
  /usr/local/etc/consul-template-metrics.d/consul-template-metrics.hcl
chmod 600 \
  /usr/local/etc/consul-template-metrics.d/consul-template-metrics.hcl
echo "s${sep}%%token%%${sep}$TOKEN${sep}" | sed -i '' -f - \
  /usr/local/etc/consul-template-metrics.d/consul-template-metrics.hcl

< "$TEMPLATEPATH/metrics.crt.tpl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
  > /mnt/templates/metrics.crt.tpl

< "$TEMPLATEPATH/metrics.key.tpl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
  > /mnt/templates/metrics.key.tpl

< "$TEMPLATEPATH/metrics-ca.crt.tpl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
  > /mnt/templates/metrics-ca.crt.tpl

echo "Enabling and starting consul-template-metrics"
sysrc consul_template_metrics_syslog_output_enable=YES
service consul-template-metrics enable
