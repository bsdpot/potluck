#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
#sep=$'\001'
#

# we're not currently making any changes to
# clamd.conf, clamav-milter.conf or freshclam.conf
# so we can skip the template processing.
# files are in templates directory for future use.


# redundant step but do it anyway
# create clamav run directory and set ownership to clamav
mkdir -p /var/run/clamav
chown -R clamav:clamav /var/run/clamav

# enable service
sysrc clamav_clamd_enable="YES"
sysrc clamav_freshclam_enable="YES"
sysrc clamav_milter_enable="YES"
