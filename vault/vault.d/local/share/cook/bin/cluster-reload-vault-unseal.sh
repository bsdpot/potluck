#!/bin/sh
cat /mnt/unsealcerts/ca.crt /mnt/unsealcerts/ca_root.crt \
  >/mnt/unsealcerts/ca_chain.crt.tmp
chown vault /mnt/unsealcerts/*
mv /mnt/unsealcerts/ca_chain.crt.tmp /mnt/unsealcerts/ca_chain.crt

NEW_ENDDATE=$(date -j -f "%b %d %T %Y %Z" \
  "$(< /mnt/unsealcerts/client.crt \
  openssl x509 -enddate -noout | cut -d= -f2)" "+%s")
OLD_ENDDATE=$(date -j -f "%b %d %T %Y %Z" \
 "$(< /mnt/unsealcerts/client.crt.bak \
   openssl x509 -enddate -noout | cut -d= -f2)" "+%s")

if [ "$((NEW_ENDDATE - OLD_ENDDATE))" -gt 10 ]; then
  sleep 1
  service vault reload
  sleep 1
  service consul-template-unseal reload
fi
exit 0
