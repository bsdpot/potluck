#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

if ! id -u "zincsearch" >/dev/null 2>&1; then
  /usr/sbin/pw useradd -n zincsearch -c 'zincsearch user' -m -s /usr/sbin/nologin -h -
fi

# make sure the data directory is created
# the default is /mnt/zinc/data
if [ -n "${ZINCDATA}" ]; then
    mkdir -p "$ZINCDATA"
    chown -R zincsearch:zincsearch "$ZINCDATA"
	chmod 775 "$ZINCDATA"
fi

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/zincsearch.rc.in" \
  sed "s${sep}%%zincuser%%${sep}$ZINCUSER${sep}g" | \
  sed "s${sep}%%zincpass%%${sep}$ZINCPASS${sep}g" | \
  sed "s${sep}%%zincport%%${sep}$ZINCPORT${sep}g" | \
  sed "s${sep}%%zincdata%%${sep}$ZINCDATA${sep}g" \
  > /usr/local/etc/rc.d/zincsearch

# set execute permissions
chmod 755 /usr/local/etc/rc.d/zincsearch

# enable zincsearch
service zincsearch enable || true

# start zincsearch
service zincsearch start || true
