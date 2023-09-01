#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# this is for runj networking with a bridge and pf setup on host beforehand

# configure the epair0b interface to the passed in IP address
ifconfig epair0b inet "$IP/16"

# add a route to the passed in gateway
route -4 add default "$ALTNETWORK"

# we should have networking now, pass in default resolver
# to-do: make this configurable with a parameter
echo "nameserver 8.8.8.8" > /etc/resolv.conf
