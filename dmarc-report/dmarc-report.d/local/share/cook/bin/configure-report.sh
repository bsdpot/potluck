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

# make directory and set permissions
mkdir -p /root/bin/

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
#sep=$'\001'

# copy the python script to generate the report
cp -f "$TEMPLATEPATH/makereport.py.in" /root/bin/makereport.py

# copy the file to check CSV then run report
cp -f "$TEMPLATEPATH/runreport.sh.in" /root/bin/runreport.sh
chmod +x /root/bin/runreport.sh

# to-do
# run the report AFTER dmarc has processed messages
# attempting this with cron every hour
# shellcheck disable=SC2035
echo \"0 * * * * root /root/bin/runreport.sh\" >> /etc/crontab
