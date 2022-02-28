#!/bin/sh

# reload/restart services
# if sysylog-ng is enabled, then restart or reload it
if service syslog-ng enabled; then
    if service syslog-ng status; then
        service syslog-ng reload
    else
        service syslog-ng restart
    fi
fi

service nginx reload nodemetricsproxy
service nginx reload grafanaproxy

exit 0
