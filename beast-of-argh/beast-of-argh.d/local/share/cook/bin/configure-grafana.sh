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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

## start grafana config

# create log dir
mkdir -p /mnt/applog/grafana
chown -R grafana:grafana /mnt/applog/grafana

# removed influxdb for now
#if ! echo "$INFLUXDBSOURCE" | grep -qF ":"; then
#  INFLUXDBSOURCE="$INFLUXDBSOURCE:8086"
#fi

# dashboard sources
# https://raw.githubusercontent.com/lux4rd0/grafana-loki-syslog-aio/main/config/grafana/dashboards/no_folder/loki_syslog_aio_overview.json
# https://grafana.com/grafana/dashboards/15764-nomad/
# https://promcat.io/apps/redis
#
# removed as no longer working
# https://raw.githubusercontent.com/mr-karan/nomad-monitoring/main/dashboards/allocations.json
# https://raw.githubusercontent.com/mr-karan/nomad-monitoring/main/dashboards/clients.json
# https://raw.githubusercontent.com/mr-karan/nomad-monitoring/main/dashboards/server.json
#
# Todo: pull these in from source

# if /mnt/grafana is empty, copy in /var/db/grafana
if [ ! -f /mnt/grafana/grafana.db ]; then
    # if empty we need to copy in the directory structure from install
    cp -a /var/db/grafana /mnt
    # new: we get the provisioning directory from here now
    #  /usr/local/etc/grafana/provisioning
    cp -a /usr/local/etc/grafana/provisioning /mnt/grafana

    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

	# this seems to be fixed, to-do: remove the edited rc file from sources
    # overwrite the rc file with a fixed one as per
    # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255676
    #cp "$TEMPLATEPATH/grafana.rc.in" /usr/local/etc/rc.d/grafana
    #chmod 755 /usr/local/etc/rc.d/grafana

    # this seems to be required, grafana still crashes without it
    chmod 755 /root

    # removed influxdb for now
    ## copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    #< "$TEMPLATEPATH/datasources.yml.in" \
    #  sed "s${sep}%%ip%%${sep}$IP${sep}g" |\
    #  sed "s${sep}%%influxdbsource%%${sep}$INFLUXDBSOURCE${sep}g" |\
    #  sed "s${sep}%%influxdbname%%${sep}$INFLUXDBNAME${sep}g" \
    #  > /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    < "$TEMPLATEPATH/datasources.yml.in" \
      sed "s${sep}%%ip%%${sep}$IP${sep}g" \
      > /mnt/grafana/provisioning/datasources/datasources.yml

    chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    cp "$TEMPLATEPATH/dashboard.yml.in" \
      /mnt/grafana/provisioning/dashboards/default.yml
    # include the relevant .json for actual dashboard as follows
    # using https://raw.githubusercontent.com/rfrail3/grafana-dashboards/\
    # master/prometheus/node-exporter-freebsd.json
    # as source dashboard json for demo purposes
    cp "$TEMPLATEPATH/home.json.in" \
      /mnt/grafana/provisioning/dashboards/home.json
    cp "$TEMPLATEPATH/homelogs.json.in" \
      /mnt/grafana/provisioning/dashboards/homelogs.json
    cp "$TEMPLATEPATH/newhomelogs.json.in" \
      /mnt/grafana/provisioning/dashboards/newhomelogs.json
    #cp "$TEMPLATEPATH/vault.json.in" \
    #  /mnt/grafana/provisioning/dashboards/vault.json
    cp "$TEMPLATEPATH/consulcluster.json.in" \
      /mnt/grafana/provisioning/dashboards/consulcluster.json
    cp "$TEMPLATEPATH/postgres.json.in" \
      /mnt/grafana/provisioning/dashboards/postgres.json
    cp "$TEMPLATEPATH/mysql.json.in" \
      /mnt/grafana/provisioning/dashboards/mysql.json
    cp "$TEMPLATEPATH/minio.json.in" \
      /mnt/grafana/provisioning/dashboards/minio.json
    cp "$TEMPLATEPATH/redis.json.in" \
      /mnt/grafana/provisioning/dashboards/redis.json
    cp "$TEMPLATEPATH/blackbox.json.in" \
      /mnt/grafana/provisioning/dashboards/blackbox.json
	# removing as not working any more, using hashicorp supplied dashboard now
    #cp "$TEMPLATEPATH/nomadallocations.json.in" \
    #  /mnt/grafana/provisioning/dashboards/nomadallocations.json
    #cp "$TEMPLATEPATH/nomadclient.json.in" \
    #  /mnt/grafana/provisioning/dashboards/nomadclient.json
    #cp "$TEMPLATEPATH/nomadservers.json.in" \
    #  /mnt/grafana/provisioning/dashboards/nomadservers.json
	# hashicorp supplied from https://grafana.com/grafana/dashboards/15764-nomad/
	# add manually as file
    cp "$TEMPLATEPATH/nomadcluster.json.in" \
      /mnt/grafana/provisioning/dashboards/nomadcluster.json

    # set ownership
    chown -R grafana:grafana /mnt/grafana/provisioning/dashboards/
else
    # if /mnt/grafana exists then don't copy in /var/db/grafana
    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

	# this seems to fixed, see to-do above
    # overwrite the rc file with a fixed one as per
    # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255676
    #cp "$TEMPLATEPATH/grafana.rc.in" /usr/local/etc/rc.d/grafana
    #chmod 755 /usr/local/etc/rc.d/grafana

    # this seems to be required, grafana still crashes without it
    chmod 755 /root

    # removed influxdb for now
    ## copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    #< "$TEMPLATEPATH/datasources.yml.in" \
    #  sed "s${sep}%%ip%%${sep}$IP${sep}g" |\
    #  sed "s${sep}%%influxdbsource%%${sep}$INFLUXDBSOURCE${sep}g" |\
    #  sed "s${sep}%%influxdbname%%${sep}$INFLUXDBNAME${sep}g" \
    #  > /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    < "$TEMPLATEPATH/datasources.yml.in" \
      sed "s${sep}%%ip%%${sep}$IP${sep}g" \
      > /mnt/grafana/provisioning/datasources/datasources.yml

    chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    cp "$TEMPLATEPATH/dashboard.yml.in" \
      /mnt/grafana/provisioning/dashboards/default.yml
    # include the relevant .json for actual dashboard as follows
    # using https://raw.githubusercontent.com/rfrail3/grafana-dashboards/\
    # master/prometheus/node-exporter-freebsd.json
    # as source dashboard json for demo purposes
    cp "$TEMPLATEPATH/home.json.in" \
      /mnt/grafana/provisioning/dashboards/home.json
    cp "$TEMPLATEPATH/homelogs.json.in" \
      /mnt/grafana/provisioning/dashboards/homelogs.json
    cp "$TEMPLATEPATH/newhomelogs.json.in" \
      /mnt/grafana/provisioning/dashboards/newhomelogs.json
    #cp "$TEMPLATEPATH/vault.json.in" \
    #  /mnt/grafana/provisioning/dashboards/vault.json
    cp "$TEMPLATEPATH/consulcluster.json.in" \
      /mnt/grafana/provisioning/dashboards/consulcluster.json
    cp "$TEMPLATEPATH/postgres.json.in" \
      /mnt/grafana/provisioning/dashboards/postgres.json
    cp "$TEMPLATEPATH/mysql.json.in" \
      /mnt/grafana/provisioning/dashboards/mysql.json
    cp "$TEMPLATEPATH/minio.json.in" \
      /mnt/grafana/provisioning/dashboards/minio.json
    cp "$TEMPLATEPATH/redis.json.in" \
      /mnt/grafana/provisioning/dashboards/redis.json
    cp "$TEMPLATEPATH/blackbox.json.in" \
      /mnt/grafana/provisioning/dashboards/blackbox.json
	# removing as not working any more, using hashicorp supplied dashboard now
    #cp "$TEMPLATEPATH/nomadallocations.json.in" \
    #  /mnt/grafana/provisioning/dashboards/nomadallocations.json
    #cp "$TEMPLATEPATH/nomadclient.json.in" \
    #  /mnt/grafana/provisioning/dashboards/nomadclient.json
    #cp "$TEMPLATEPATH/nomadservers.json.in" \
    #  /mnt/grafana/provisioning/dashboards/nomadservers.json
	# hashicorp supplied from https://grafana.com/grafana/dashboards/15764-nomad/
	# add manually as file
    cp "$TEMPLATEPATH/nomadcluster.json.in" \
      /mnt/grafana/provisioning/dashboards/nomadcluster.json

    # set ownership
    chown -R grafana:grafana /mnt/grafana/provisioning/dashboards/
fi

# config file has been updated to grafani.ini
# local edits for grafana.ini here
# the mount path for some options is set to /mnt/grafana/...
< "$TEMPLATEPATH/grafana.ini.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%grafanauser%%${sep}$GRAFANAUSER${sep}g" | \
  sed "s${sep}%%grafanapassword%%${sep}$GRAFANAPASSWORD${sep}g" \
  > /usr/local/etc/grafana/grafana.ini

# set permissions on grafana.ini
chown grafana:grafana /usr/local/etc/grafana/grafana.ini

# enable grafana service
# 'service grafana enable' not working for some reason, use sysrc method
sysrc grafana_enable="YES"
# config file hasn't been renamed to grafani.ini yet
sysrc grafana_config="/usr/local/etc/grafana/grafana.ini"
sysrc grafana_user="grafana"
sysrc grafana_group="grafana"
sysrc grafana_syslog_output_enable="YES"
