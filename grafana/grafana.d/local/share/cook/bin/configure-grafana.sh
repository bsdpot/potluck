#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

## start grafana config

# if /mnt/grafana is empty, copy in /var/db/grafana
if [ ! -f /mnt/grafana/grafana.db ]; then
    # if empty we need to copy in the directory structure from install
    cp -a /var/db/grafana /mnt

    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

    # overwrite the rc file with a fixed one as per
    # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255676
    < "$TEMPLATEPATH/grafana.rc.in" > /usr/local/etc/rc.d/grafana
    chmod 755 /usr/local/etc/rc.d/grafana
    # this seems to be required, grafana still crashes without it
    chmod 755 /root

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    < "$TEMPLATEPATH/datasources.yml.in" \
      sed "s${sep}%%mypromhost%%${sep}$PROMSOURCE${sep}g" | \
      sed "s${sep}%%mylokihost%%${sep}$LOKISOURCE${sep}g" | \
      sed "s${sep}%%myinfluxdatabase%%${sep}$INFLUXDATABASE${sep}g" | \
      sed "s${sep}%%myinfluxhost%%${sep}$INFLUXDBSOURCE${sep}g" | \
    > /mnt/grafana/provisioning/datasources/datasources.yml

    chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    < "$TEMPLATEPATH/dashboard.yml.in" > /mnt/grafana/provisioning/dashboards/default.yml
    # include the relevant .json for actual dashboard as follows
    # using https://raw.githubusercontent.com/rfrail3/grafana-dashboards/master/prometheus/node-exporter-freebsd.json
    # as source dashboard json for demo purposes
    < "$TEMPLATEPATH/home.json.in" > /mnt/grafana/provisioning/dashboards/home.json
    < "$TEMPLATEPATH/homelogs.json.in" > /mnt/grafana/provisioning/dashboards/homelogs.json
    < "$TEMPLATEPATH/vault.json.in" > /mnt/grafana/provisioning/dashboards/vault.json
    < "$TEMPLATEPATH/nomadcluster.json.in" > /mnt/grafana/provisioning/dashboards/nomadcluster.json
    < "$TEMPLATEPATH/nomadjobs.json.in" > /mnt/grafana/provisioning/dashboards/nomadjobs.json
    < "$TEMPLATEPATH/consulcluster.json.in" > /mnt/grafana/provisioning/dashboards/consulcluster.json
    < "$TEMPLATEPATH/postgres.json.in" > /mnt/grafana/provisioning/dashboards/postgres.json

    # set ownership
    chown -R grafana:grafana /mnt/grafana/provisioning/dashboards/
else
    # if /mnt/grafana exists then don't copy in /var/db/grafana
    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

    # overwrite the rc file with a fixed one as per
    # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255676
    < "$TEMPLATEPATH/grafana.rc.in" > /usr/local/etc/rc.d/grafana
    chmod 755 /usr/local/etc/rc.d/grafana
    # this seems to be required, grafana still crashes without it
    chmod 755 /root

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    < "$TEMPLATEPATH/datasources.yml.in" \
      sed "s${sep}%%mypromhost%%${sep}$PROMSOURCE${sep}g" | \
      sed "s${sep}%%mylokihost%%${sep}$LOKISOURCE${sep}g" | \
      sed "s${sep}%%myinfluxdatabase%%${sep}$INFLUXDATABASE${sep}g" | \
      sed "s${sep}%%myinfluxhost%%${sep}$INFLUXDBSOURCE${sep}g" | \
    > /mnt/grafana/provisioning/datasources/datasources.yml

    chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    < "$TEMPLATEPATH/dashboard.yml.in" > /mnt/grafana/provisioning/dashboards/default.yml
    # include the relevant .json for actual dashboard as follows
    # using https://raw.githubusercontent.com/rfrail3/grafana-dashboards/master/prometheus/node-exporter-freebsd.json
    # as source dashboard json for demo purposes
    < "$TEMPLATEPATH/home.json.in" > /mnt/grafana/provisioning/dashboards/home.json
    < "$TEMPLATEPATH/homelogs.json.in" > /mnt/grafana/provisioning/dashboards/homelogs.json
    < "$TEMPLATEPATH/vault.json.in" > /mnt/grafana/provisioning/dashboards/vault.json
    < "$TEMPLATEPATH/nomadcluster.json.in" > /mnt/grafana/provisioning/dashboards/nomadcluster.json
    < "$TEMPLATEPATH/nomadjobs.json.in" > /mnt/grafana/provisioning/dashboards/nomadjobs.json
    < "$TEMPLATEPATH/consulcluster.json.in" > /mnt/grafana/provisioning/dashboards/consulcluster.json
    < "$TEMPLATEPATH/postgres.json.in" > /mnt/grafana/provisioning/dashboards/postgres.json

    # set ownership
    chown -R grafana:grafana /mnt/grafana/provisioning/dashboards/
fi

# local edits for grafana.conf here
# the mount path for some options is set to /mnt/grafana/...
< "$TEMPLATEPATH/grafana.conf.in" \
  sed "s${sep}%%grafanauser%%${sep}$GRAFANAUSER${sep}g" | \
  sed "s${sep}%%grafanapassword%%${sep}$GRAFANAPASSWORD${sep}g" \
> /usr/local/etc/grafana.conf

# enable grafana service
service grafana enable
sysrc grafana_config="/usr/local/etc/grafana.conf"
sysrc grafana_user="grafana"
sysrc grafana_group="grafana"
sysrc grafana_syslog_output_enable="YES"
