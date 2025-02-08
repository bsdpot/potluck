#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# make some directories and set owner opensearch
mkdir -p /mnt/opensearch
chown -R opensearch:opensearch /mnt/opensearch
mkdir -p /var/log/opensearch
chown -R opensearch:opensearch /var/log/opensearch

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# create a custom opensearch.yml file that listens on IP:PORT
# the data directory is set to /mnt/opensearch by default
# instead of /var/db/opensearch
< "$TEMPLATEPATH/opensearch.yml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%port%%${sep}$SETPORT${sep}g" \
  > /usr/local/etc/opensearch/opensearch.yml

# set ownership
chown opensearch:opensearch /usr/local/etc/opensearch/opensearch.yml

# enable the service
service opensearch enable
