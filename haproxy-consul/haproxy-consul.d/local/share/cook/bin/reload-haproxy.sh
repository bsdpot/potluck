#!/bin/sh

# shellcheck disable=SC1004
lockf -t 60 /var/tmp/reload-haproxy.lock sh -c '
echo "show servers state" | /usr/local/bin/socat - /var/run/haproxy/socket \
 >"/var/tmp/haproxy.state"
service haproxy softreload
'

exit 0
