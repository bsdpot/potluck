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

# create backup script
cp -f "$TEMPLATEPATH/cronbackup.sh.in" /root/cronbackup.sh
chmod +x /root/cronbackup.sh

# add cron job
DESTINATION="$CRONBACKUP"
echo "0 3 * * *  root  /root/cronbackup.sh $DESTINATION" >> /etc/crontab
