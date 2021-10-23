#!/bin/sh
cat /mnt/consulcerts/ca.crt /mnt/consulcerts/ca_root.crt \
  >/mnt/consulcerts/ca_chain.crt.tmp
chown consul /mnt/consulcerts/*
mv /mnt/consulcerts/ca_chain.crt.tmp /mnt/consulcerts/ca_chain.crt

service consul reload
exit 0
