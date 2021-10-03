#!/bin/sh
cat /mnt/postgrescerts/ca.crt /mnt/postgrescerts/ca_root.crt \
  >/mnt/postgrescerts/ca_chain.crt.tmp
chown postgres /mnt/postgrescerts/*
mv /mnt/postgrescerts/ca_chain.crt.tmp /mnt/postgrescerts/ca_chain.crt

# restart gives error with port already in use when using this
#  /usr/local/etc/rc.d/patroni restart
# so we're using this instead
/usr/local/bin/patronictl -c /usr/local/etc/patroni/patroni.yml reload postgresql --force
exit 0
