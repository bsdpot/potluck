#!/bin/sh

cat /mnt/servicecerts/ca.crt \
  /mnt/servicecerts/ca_root.crt \
  >/mnt/servicecerts/ca_chain.crt.tmp
mv /mnt/servicecerts/ca_chain.crt.tmp \
  /mnt/servicecerts/ca_chain.crt

(
  umask 177
  cat /mnt/servicecerts/client.crt \
    /mnt/servicecerts/client.key \
    /mnt/servicecerts/ca_chain.crt \
    >/usr/local/etc/haproxy/certs/serviceclient.pem
  cp /mnt/servicecerts/ca_chain.crt \
    /usr/local/etc/haproxy/certs/service-ca.pem
)

# shellcheck disable=SC1004
lockf -t 60 /var/tmp/reload-haproxy.lock sh -c '
echo "show servers state" | /usr/local/bin/socat - /var/run/haproxy/socket \
 >"/var/tmp/haproxy.state"
service haproxy softreload
'

exit 0
