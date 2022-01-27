#!/bin/sh

# shellcheck disable=SC1004
lockf -t 20 /tmp/reload-patroni.lock sh -c '
  set -e
  cp -a /mnt/postgrescerts/postgresserver.key.next \
    /mnt/postgrescerts/postgresserver.key
  cp -a /mnt/postgrescerts/postgresserver.crt.next \
    /mnt/postgrescerts/postgresserver.crt
  cp -a /mnt/postgrescerts/postgresca.crt.next /mnt/postgrescerts/postgresca.crt
  cat /mnt/postgrescerts/postgresca.crt /mnt/postgrescerts/ca_root.crt \
    >/mnt/postgrescerts/ca_chain.crt.tmp
  chown postgres /mnt/postgrescerts/*
  mv /mnt/postgrescerts/ca_chain.crt.tmp /mnt/postgrescerts/ca_chain.crt
  service patroni reload'

exit 0
