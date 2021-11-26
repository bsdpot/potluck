#!/bin/sh
cat /mnt/certs/ca.crt /mnt/certs/ca_root.crt \
  >/mnt/certs/ca_chain.crt.tmp
chown postgres /mnt/certs/*
mv /mnt/certs/ca_chain.crt.tmp /mnt/certs/ca_chain.crt

NEW_ENDDATE=$(date -j -f "%b %d %T %Y %Z" \
  "$(< /mnt/certs/client.crt \
    openssl x509 -enddate -noout | cut -d= -f2)" "+%s")
OLD_ENDDATE=$(date -j -f "%b %d %T %Y %Z" \
  "$(< /mnt/certs/client.crt.bak \
    openssl x509 -enddate -noout | cut -d= -f2)" "+%s")

if [ "$((NEW_ENDDATE - OLD_ENDDATE))" -gt 10 ]; then
  daemon -Sf sh -c "timeout 3 \
    service consul-template stop; sleep 1;
    service consul-template restart"
  #service patroni reload
  /usr/local/bin/patronictl -c /usr/local/etc/patroni/patroni.yml reload \
    postgresql --force
fi
exit 0
