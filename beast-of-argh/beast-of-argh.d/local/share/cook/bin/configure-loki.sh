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

# setup directories for loki
mkdir -p /mnt/loki/rules-temp
mkdir -p /tmp/loki
mkdir -p /mnt/applog/loki
mkdir -p /mnt/applog/promtail

# loki setup

# removed as pkg install should cover it (2024-07-08)
## create loki user
#/usr/sbin/pw useradd -n loki -c 'loki user' -m -s /usr/sbin/nologin -h -

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# removed as pkg install should cover it (2024-07-08)
## copy in loki rc
#cp -f "$TEMPLATEPATH/loki.rc.in" /usr/local/etc/rc.d/loki
#chmod +x /usr/local/etc/rc.d/loki

service loki enable || true

# this is invalid  on pkg install grafana-loki
# logs are in /var/log/loki/loki.log
#sysrc loki_syslog_output_enable="YES" || true

# not specifically needed if permissions on /tmp/loki and loki-local-config.yaml
# are correct
#sysrc loki_user="loki"
#sysrc loki_group="loki"

# add this in for pkg install of grafana-loki to allow legacy setup stay same (2024-07-08)
sysrc loki_config="/usr/local/etc/loki-local-config.yaml"
sysrc loki_logfile="/mnt/applog/loki/loki.log"

# copy in loki config file, make sure loki can RW it
< "$TEMPLATEPATH/loki-local-config.yaml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/loki-local-config.yaml

# patch startup script
sed -i '' 's/command_args="-p/command_args="-f -p/' \
  /usr/local/etc/rc.d/loki

# set permissions on directories and files
chown loki:loki /usr/local/etc/loki-local-config.yaml
chown -R loki:loki /mnt/loki
chown -R loki:loki /tmp/loki
chown -R loki:loki /mnt/applog/loki

# promtail setup
# promtail needs a directory it has permission to write to
mkdir -p /mnt/promtail

# promtail default group is loki, setting to use promtail group
chown -R promtail:promtail /mnt/promtail
chown -R promtail:promtail /mnt/applog/promtail

# removed as pkg install should cover it (2024-07-08)
# copy in the promtail rc file
#cp "$TEMPLATEPATH/promtail.rc.in" /usr/local/etc/rc.d/promtail
#chmod +x /usr/local/etc/rc.d/promtail

# patch startup script
sed -i '' 's/command_args="-p/command_args="-f -p/' \
  /usr/local/etc/rc.d/promtail

service promtail enable || true

# promtail needs to run with root perms because syslog-ng is saving
# log files to /mnt/logs/remote and the files have 600 perms
# disabled #
# trying with read perms configured in syslog-ng instead
# sysrc promtail_user="root"

# invalid with pkg install grafana-loki
# logs are in /var/log/promtail/promtail.log
#sysrc promtail_syslog_output_enable="YES" || true

# specify log file
sysrc promtail_logfile="/mnt/applog/promtail/promtail.log"

# add this in for pkg install of grafana-loki to allow legacy setup stay same (2024-07-08)
sysrc promtail_config="/usr/local/etc/promtail-local-config.yaml"

# copy in the promtail config file
< "$TEMPLATEPATH/promtail-local-config.yaml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/promtail-local-config.yaml

# correct permissions of existing log files (for upgrading)
mkdir -p /mnt/logs/remote/metrics
find /mnt/logs/remote -name "*.log" -exec chmod 640 {} \;
find /mnt/logs/remote -name "*.log" -exec chgrp promtail {} \;