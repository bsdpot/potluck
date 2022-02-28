#!/bin/sh

# restart services
# if sysylog-ng is enabled, then restart it
if service syslog-ng enabled; then
    if service syslog-ng status; then
        service syslog-ng reload
    else
        service syslog-ng restart
    fi
fi

service nginx reload nodemetricsproxy
service nginx reload postgresmetricsproxy

exit 0
