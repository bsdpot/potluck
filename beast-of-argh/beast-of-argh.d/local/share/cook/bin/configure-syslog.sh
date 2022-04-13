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

# create remote log dir
mkdir -p /mnt/logs/remote

# create empty log file
touch /mnt/logs/remote/central.log

# create /usr/local/etc/syslog.d
mkdir -p /usr/local/etc/syslog.d

# copy in the template log capture entry
cp -f "${TEMPLATEPATH}/remotelogs.conf.in" /usr/local/etc/syslog.d/remotelogs.conf

# configure /etc/rc.conf for local network range to allow logging from
echo "syslogd_flags=\"-b ${IP} -a ${MYNETWORK}:* -vv\"" >> /etc/rc.conf

# setup log rotation
mkdir -p /usr/local/etc/newsyslog.conf.d/

# copy in template log rotate entry
cp -f "${TEMPLATEPATH}/rotateremote.conf.in" /usr/local/etc/newsyslog.conf.d/remotelogs.conf

# restart syslog
service -v syslogd restart

# restart newsyslog
service -v newsyslog restart
