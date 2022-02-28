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

# copy in syslog-ng.conf
if [ -n "$REMOTELOG" ] && [ "$REMOTELOG" != "null" ]; then
    config_version=$(/usr/local/sbin/syslog-ng --version | \
      grep "^Config version:" | awk -F: '{ print $2 }' | xargs)

    # read in template conf file, update remote log IP address, and
    # write to correct destination
    < "$TEMPLATEPATH/syslog-ng.conf.in" \
      sed "s${sep}%%config_version%%${sep}$config_version${sep}g" | \
      sed "s${sep}%%remotelogip%%${sep}$REMOTELOG${sep}g" \
      > /usr/local/etc/syslog-ng.conf

    # stop and disable syslogd
    service syslogd onestop || true
    service syslogd disable

    # enable and start syslog-ng
    service syslog-ng enable
    #sysrc syslog_ng_flags="-u daemon"
    sysrc syslog_ng_flags="-R /tmp/syslog-ng.persist"
    service syslog-ng start
else
    echo "REMOTELOG parameter is not set to an IP address. syslog-ng won't \
operate."
fi
