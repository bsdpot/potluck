#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
#sep=$'\001'
#

# nothing to configure

# enable service
sysrc clamav_clamd_enable="YES"
sysrc clamav_freshclam_enable="YES"
sysrc clamav_milter_enable="YES"
