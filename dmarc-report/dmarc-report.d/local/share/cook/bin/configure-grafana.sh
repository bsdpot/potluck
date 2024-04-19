#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

## start grafana config

# create log dir
mkdir -p /mnt/applog/grafana
chown -R grafana:grafana /mnt/applog/grafana

# if /mnt/grafana is empty, copy in /var/db/grafana
if [ ! -f /mnt/grafana/grafana.db ]; then
    # if empty we need to copy in the directory structure from install
    cp -a /var/db/grafana /mnt
    # new: we get the provisioning directory from here now
    #  /usr/local/etc/grafana/provisioning
    cp -a /usr/local/etc/grafana/provisioning /mnt/grafana

    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

    # this seems to be required, grafana still crashes without it
    chmod 755 /root

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    < "$TEMPLATEPATH/datasources.yml.in" \
      sed "s${sep}%%ip%%${sep}$IP${sep}g" \
      > /mnt/grafana/provisioning/datasources/datasources.yml

    chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    cp "$TEMPLATEPATH/dashboard.yml.in" \
      /mnt/grafana/provisioning/dashboards/default.yml

	# including default dmarc dashboard (WIP)
    cp "$TEMPLATEPATH/home.json.in" \
      /mnt/grafana/provisioning/dashboards/home.json

    # set ownership
    chown -R grafana:grafana /mnt/grafana/provisioning/dashboards/
else
    # if /mnt/grafana exists then don't copy in /var/db/grafana
    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

    # this seems to be required, grafana still crashes without it
    chmod 755 /root

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    < "$TEMPLATEPATH/datasources.yml.in" \
      sed "s${sep}%%ip%%${sep}$IP${sep}g" \
      > /mnt/grafana/provisioning/datasources/datasources.yml

    chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    cp "$TEMPLATEPATH/dashboard.yml.in" \
      /mnt/grafana/provisioning/dashboards/default.yml

	# including default dmarc dashboard (WIP)
    cp "$TEMPLATEPATH/home.json.in" \
      /mnt/grafana/provisioning/dashboards/home.json

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
