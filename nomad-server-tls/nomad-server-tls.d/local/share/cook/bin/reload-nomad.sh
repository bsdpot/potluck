#!/bin/sh
cat /mnt/nomadcerts/ca.crt /mnt/nomadcerts/ca_root.crt \
  >/mnt/nomadcerts/ca_chain.crt.tmp
chown nomad /mnt/nomadcerts/*
mv /mnt/nomadcerts/ca_chain.crt.tmp /mnt/nomadcerts/ca_chain.crt

service nomad reload
exit 0
