#!/bin/sh

# shellcheck disable=SC1004
# lock named "reload-patroni" on purpose
lockf -t 20 /tmp/reload-patroni.lock sh -c '
  set -e
  cp -a /mnt/consulcerts/agent.key.next \
    /mnt/consulcerts/agent.key
  cp -a /mnt/consulcerts/agent.crt.next \
    /mnt/consulcerts/agent.crt
  cp -a /mnt/consulcerts/ca.crt.next /mnt/consulcerts/ca.crt
  cat /mnt/consulcerts/ca.crt /mnt/consulcerts/ca_root.crt \
    >/mnt/consulcerts/ca_chain.crt.tmp
  chown consul /mnt/consulcerts/*
  mv /mnt/consulcerts/ca_chain.crt.tmp /mnt/consulcerts/ca_chain.crt
  service consul reload
  service patroni reload
'

exit 0
