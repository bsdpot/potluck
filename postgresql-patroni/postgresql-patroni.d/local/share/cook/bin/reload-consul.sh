#!/bin/sh
cat /mnt/consulcerts/ca.crt /mnt/consulcerts/ca_root.crt \
  >/mnt/consulcerts/ca_chain.crt.tmp
chown consul /mnt/consulcerts/*
mv /mnt/consulcerts/ca_chain.crt.tmp /mnt/consulcerts/ca_chain.crt

service consul reload
# XXX: this is a bit dangerous, as it might clash with
# reload-patroni.sh
/usr/local/bin/patronictl -c /usr/local/etc/patroni/patroni.yml reload \
  postgresql --force

exit 0
