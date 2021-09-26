#!/bin/sh
cat /mnt/certs/ca.crt /mnt/certs/ca_root.crt \
  >/mnt/certs/ca_chain.crt.tmp
chown vault /mnt/certs/*
mv /mnt/certs/ca_chain.crt.tmp /mnt/certs/ca_chain.crt

NEW_ENDDATE=$(date -j -f "%b %d %T %Y %Z" \
  "$(< /mnt/certs/agent.crt \
  openssl x509 -enddate -noout | cut -d= -f2)" "+%s")
OLD_ENDDATE=$(date -j -f "%b %d %T %Y %Z" \
 "$(< /mnt/certs/agent.crt.bak \
   openssl x509 -enddate -noout | cut -d= -f2)" "+%s")

if [ "$((NEW_ENDDATE - OLD_ENDDATE))" -gt 10 ]; then
  sleep 1.5
  service vault reload
  sleep 0.5
  service consul-template reload
  service consul-template-consul reload
fi
exit 0
