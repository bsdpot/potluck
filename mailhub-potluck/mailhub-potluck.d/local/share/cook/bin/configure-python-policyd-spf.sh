#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# make directories if they don't exist
mkdir -p /usr/local/etc/python-policyd-spf

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# setup a default policyd-spf.conf where the HELO_reject is set to SPF_Not_Pass (to be tested, adjusted)
# This replacement adds the mail domain to a comment. In future this could be expanded to set
# specific options in the file, or add hosts to ignore
< "$TEMPLATEPATH/policyd-spf.conf.in" \
  sed "s${sep}%%mailcertdomain%%${sep}$MAILCERTDOMAIN${sep}g" \
  > /usr/local/etc/python-policyd-spf/policyd-spf.conf
