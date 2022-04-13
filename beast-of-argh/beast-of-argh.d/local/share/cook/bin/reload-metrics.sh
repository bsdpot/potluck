#!/bin/sh

# reload/restart services
# if sysylogdis enabled, then restart or reload it
if service syslogd enabled; then
    if service syslogd status; then
        service syslogd reload
    else
        service syslogd restart
    fi
fi

service nginx reload nodemetricsproxy
service loki restart
service promtail restart
service nginx reload lokiproxy

exit 0
